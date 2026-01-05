/// Marks a function to be wrapped in a childSpan for OpenTelemetry tracing
@attached(body)
public macro TraceSpan(
    name: String,
    instrumentationName: String
) = #externalMacro(
    module: "OpenTelemetryExtrasMacros",
    type: "SpanMacro"
)
