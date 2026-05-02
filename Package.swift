// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NMRCalculatorMCPServer",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "NMRCalculatorMCPServer", targets: ["NMRCalculatorMCPServer"])
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk",
                 .upToNextMinor(from: "0.12.0"))
    ],
    targets: [
        .executableTarget(
            name: "NMRCalculatorMCPServer",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
            ]
        )
    ]
)
