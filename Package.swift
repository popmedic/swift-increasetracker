// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "swift-increasetracker",
    products: [
        .library(
            name: "IncreaseTracker",
            targets: ["IncreaseTracker"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "IncreaseTracker",
            dependencies: []),
        .testTarget(
            name: "IncreaseTrackerTests",
            dependencies: ["IncreaseTracker"]),
    ]
)
