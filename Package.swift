// swift-tools-version: 5.8
// Swift 5.9 to support Xcode 15.2 on GitHub Actions
// Swift 5.10 requires Xcode 15.4 in GitHub Actions

import PackageDescription

var globalSwiftSettings: [PackageDescription.SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency"),
    // Swift 6 enablement
    // .enableUpcomingFeature("StrictConcurrency")
    .enableUpcomingFeature("ExistentialAny"),
    .enableExperimentalFeature("AccessLevelOnImport"),
    .enableUpcomingFeature("InternalImportsByDefault"),
]

let package = Package(
    name: "CASimEngine",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "CASimEngine",
            targets: ["CASimEngine"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/heckj/voxels", from: "0.2.0"),
    ],
    targets: [
        .target(
            name: "CASimEngine",
            dependencies: [
                .product(name: "Voxels", package: "voxels"),
            ],
            swiftSettings: globalSwiftSettings
        ),
        .testTarget(
            name: "CASimEngineTests",
            dependencies: ["CASimEngine"],
            swiftSettings: globalSwiftSettings
        ),
    ],
    swiftLanguageVersions: [.version("6"), .v5]
)
