// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftPlayground",
    targets: [
        .systemLibrary(
            name: "Raylib",
            pkgConfig: "raylib",
            providers: [
                .brew(["raylib"])
            ]
        ),
        .executableTarget(
            name: "Conway",
            dependencies: ["Raylib"]
        ),
        .executableTarget(
            name: "Shaders",
            dependencies: ["Raylib"],
            resources: [
                .copy("Resources")
            ]
        ),
    ]
)
