// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PlaylisterUI",
    defaultLocalization: "en",
    platforms: [.iOS("18.0"), .macOS("15.0")],
    products: [
        .library(name: "PlaylisterUI", targets: ["PlaylisterUI"])
    ],
    targets: [
        .target(
            name: "PlaylisterUI",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PlaylisterUITests",
            dependencies: ["PlaylisterUI"]
        )
    ],
    swiftLanguageModes: [.v6]
)
