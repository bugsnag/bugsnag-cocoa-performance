// swift-tools-version:5.3
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
        .library(
            name: "BugsnagPerformanceSwift",
            targets: ["BugsnagPerformanceSwift"]),
        .library(
            name: "BugsnagPerformanceSwiftUI",
            targets: ["BugsnagPerformanceSwiftUI"]),
    ],
    targets: [
        .target(
            name: "BugsnagPerformance",
            path: "Sources/BugsnagPerformance",
            resources: [
               .copy("resources/PrivacyInfo.xcprivacy")
            ],
            linkerSettings: [
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("UIKit"),
                .linkedFramework("CoreTelephony", .when(platforms: [.iOS])),
            ]
        ),
        .target(
            name: "BugsnagPerformanceSwift",
            dependencies: ["BugsnagPerformance"],
            path: "Sources/BugsnagPerformanceSwift"
        ),
        .target(
            name: "BugsnagPerformanceSwiftUI",
            dependencies: ["BugsnagPerformance"],
            path: "Sources/BugsnagPerformanceSwiftUI/"
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
