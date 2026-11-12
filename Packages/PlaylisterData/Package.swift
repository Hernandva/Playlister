// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PlaylisterData",
    platforms: [.iOS("18.0"), .macOS("15.0")],
    products: [
        .library(name: "PlaylisterData", targets: ["PlaylisterData"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.0")
    ],
    targets: [
        .target(
            name: "PlaylisterData",
            dependencies: [.product(name: "Alamofire", package: "Alamofire")]
        ),
        .testTarget(
            name: "PlaylisterDataTests",
            dependencies: ["PlaylisterData"]
        )
    ],
    swiftLanguageModes: [.v6]
)
