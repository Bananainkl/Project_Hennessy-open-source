// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Hennessy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Hennessy", targets: ["Hennessy"])
    ],
    targets: [
        .executableTarget(name: "Hennessy"),
        .testTarget(
            name: "HennessyTests",
            dependencies: ["Hennessy"]
        )
    ]
)
