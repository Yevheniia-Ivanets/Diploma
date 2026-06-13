// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyAppLogic",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "MyAppLogic",
            path: "Sources/MyAppLogic"
        ),
        .testTarget(
            name: "MyAppLogicTests",
            dependencies: ["MyAppLogic"],
            path: "Tests/MyAppLogicTests"
        )
    ]
)
