// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "clipq",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Clipq", targets: ["Clipq"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
    ],
    targets: [
        .target(name: "ClipqCore"),
        .executableTarget(
            name: "Clipq",
            dependencies: ["ClipqCore", "KeyboardShortcuts"]
        ),
        .testTarget(name: "ClipqCoreTests", dependencies: ["ClipqCore"]),
    ]
)
