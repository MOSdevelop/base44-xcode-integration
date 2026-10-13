// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Base44XcodeBridge",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Base44XcodeBridge",
            targets: ["Base44XcodeBridge"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Base44XcodeBridge",
            path: "Sources/Base44XcodeBridge"
        )
    ]
)
