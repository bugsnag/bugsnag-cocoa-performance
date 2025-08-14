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
            name: "BugsnagPerformanceNamedSpans",
            targets: ["BugsnagPerformanceNamedSpans"]),
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
            cSettings: [
                .define("NS_BLOCK_ASSERTIONS", .when(configuration: .release)),
                .define("NDEBUG", .when(configuration: .release))
            ],
            linkerSettings: [
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("UIKit"),
                .linkedFramework("CoreTelephony"),
            ]
        ),
        .target(
            name: "BugsnagPerformanceNamedSpans",
            dependencies: ["BugsnagPerformance"],
            path: "Sources/BugsnagPerformanceNamedSpans",
            cSettings: [
                .define("NS_BLOCK_ASSERTIONS", .when(configuration: .release)),
                .define("NDEBUG", .when(configuration: .release))
            ]
        ),
        .target(
            name: "BugsnagPerformanceSwift",
            dependencies: ["BugsnagPerformance"],
            path: "Sources/BugsnagPerformanceSwift",
            cSettings: [
                .define("NS_BLOCK_ASSERTIONS", .when(configuration: .release)),
                .define("NDEBUG", .when(configuration: .release))
            ]
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
        .testTarget(
            name: "BugsnagPerformanceNamedSpansTests",
            dependencies: ["BugsnagPerformance"]),
    ],
    cxxLanguageStandard: .cxx14
)
