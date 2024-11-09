// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "VoxelBenchmarks",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    dependencies: [
        .package(path: "../"),
        .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0")),
    ],
    targets: [
        .executableTarget(
            name: "EngineBenchmarks",
            dependencies: [
                "CASimEngine",
                .product(name: "Benchmark", package: "package-benchmark"),
            ],
            path: "Benchmarks/EngineBenchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),
    ]
)
