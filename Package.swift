// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "opentelemetry-swift-extras",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13),
    ],
    products: [
        .library(
            name: "OpenTelemetryExtras",
            targets: ["OpenTelemetryExtras"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/open-telemetry/opentelemetry-swift-core.git",
            .upToNextMajor(from: "2.3.0")
        ),
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            from: "602.0.0-latest"
        ),
    ],
    targets: [
        .target(
            name: "OpenTelemetryExtras",
            dependencies: [
                "OpenTelemetryExtrasMacros",
                .product(
                    name: "OpenTelemetryConcurrency",
                    package: "opentelemetry-swift-core"
                ),
            ]
        ),
        .macro(
            name: "OpenTelemetryExtrasMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        )
    ]
)
