import SwiftSyntax
import SwiftCompilerPlugin
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct SpanMacro: BodyMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("TraceSpan can only be applied to functions")
        }
        
        guard let attr = funcDecl.attributes.first?.as(AttributeSyntax.self),
              let argList = attr.arguments?.as(LabeledExprListSyntax.self),
              let spanName = argList.first?.expression,
              let instrumentationName = argList.last?.expression
        else {
            throw MacroExpansionErrorMessage("spanName and(or) instrumentationName cannot be retrieved")
        }

        let body = funcDecl.body ?? CodeBlockSyntax("{ }")
        let isAsync = funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil
        let isThrowing = funcDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier != nil
        
        // --- Build closure body explicitly ---
        let closure = ClosureExprSyntax(
            signature: ClosureSignatureSyntax(
                parameterClause: .simpleInput(
                    ClosureShorthandParameterListSyntax {
                        ClosureShorthandParameterSyntax(name: .identifier("span"))
                    }
                )
            ),
            statements: body.statements
        )
        
        // --- Build argument list ---
        let arguments = LabeledExprListSyntax {
            LabeledExprSyntax(expression: spanName)
            LabeledExprSyntax(
                label: .identifier("instrumentationName"),
                colon: .colonToken(),
                expression: instrumentationName
            )
        }
        
        // --- Build the function call ---
        let identifier = isThrowing ? "throwingChildSpan" : "childSpan"
        let call = FunctionCallExprSyntax(
            calledExpression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(identifier))),
            leftParen: .leftParenToken(),
            arguments: arguments,
            rightParen: .rightParenToken(),
            trailingClosure: closure
        )
        
        // --- Wrap with async / throws ---
        let expr: ExprSyntax
        switch (isAsync, isThrowing) {
        case (true, true):
            expr = ExprSyntax(
                TryExprSyntax(
                    expression: AwaitExprSyntax(expression: ExprSyntax(call))
                )
            )
        case (true, false):
            expr = ExprSyntax(
                AwaitExprSyntax(expression: ExprSyntax(call))
            )
        case (false, true):
            expr = ExprSyntax(
                TryExprSyntax(expression: ExprSyntax(call))
            )
        case (false, false):
            expr = ExprSyntax(call)
        }
        
        return [CodeBlockItemSyntax(item: .expr(expr))]
    }
}

@main
struct OpenTelemetryExtrasMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SpanMacro.self,
    ]
}
