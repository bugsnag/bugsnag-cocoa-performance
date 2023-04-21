// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BugsnagPerformance",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(
            name: "BugsnagPerformance",
            targets: ["BugsnagPerformance"]),
    ],
    targets: [
        .target(
            name: "BugsnagPerformance",
            linkerSettings: [
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("UIKit"),
                .linkedFramework("CoreTelephony"),
            ]
        ),
        .testTarget(
            name: "BugsnagPerformanceTests",
            dependencies: ["BugsnagPerformance"]),
        .testTarget(
            name: "BugsnagPerformanceTestsSwift",
            dependencies: ["BugsnagPerformance"]),
    ],
    cxxLanguageStandard: .cxx14
)
