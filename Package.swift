// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swiftui-simplex-architecture",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SimplexArchitecture",
            targets: ["SimplexArchitecture"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", exact: "509.0.2"),
        .package(url: "https://github.com/pointfreeco/swift-case-paths.git", exact: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump.git", exact: "1.1.2"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", exact: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swiftui-navigation.git", exact: "1.0.2"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing.git", exact: "0.1.0"),
        .package(url: "https://github.com/google/swift-benchmark", from: "0.1.2"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SimplexArchitecture",
            dependencies: [
                "SimplexArchitectureMacrosPlugin",
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "SwiftUINavigation", package: "swiftui-navigation"),
            ]
        ),
        .executableTarget(
            name: "swiftui-simplex-architecture-benchmark",
            dependencies: [
                "SimplexArchitecture",
                .product(name: "Benchmark", package: "swift-benchmark"),
            ]
        ),
        .macro(
            name: "SimplexArchitectureMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "SimplexArchitectureTests",
            dependencies: [
                "SimplexArchitecture",
                "SimplexArchitectureMacrosPlugin",
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                .product(name: "MacroTesting", package: "swift-macro-testing"),
            ]
        ),
    ]
)
