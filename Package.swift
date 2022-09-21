// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BugsnagPerformance",
    platforms: [
        .iOS("10.0"),
    ],
    products: [
        .library(
            name: "BugsnagPerformance",
            targets: ["BugsnagPerformance"]),
    ],
    targets: [
        .target(
            name: "BugsnagPerformance",
            dependencies: []),
        .testTarget(
            name: "BugsnagPerformanceTests",
            dependencies: ["BugsnagPerformance"]),
    ],
    swiftLanguageVersions: [
        .v4_2
    ]
)
