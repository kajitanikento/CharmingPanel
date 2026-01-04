// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CharmingPanelPackage",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "Core",
            targets: ["Core"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.23.1"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0")
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: [
                "Core",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)
