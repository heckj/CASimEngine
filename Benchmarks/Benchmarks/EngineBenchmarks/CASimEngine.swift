import Benchmark
import CASimEngine
import Voxels

// Benchmark documentation:
// https://swiftpackageindex.com/ordo-one/package-benchmark/documentation/benchmark/writingbenchmarks

let benchmarks = {
    Benchmark("sim iteration", configuration: .init(maxDuration: .seconds(9))) { benchmark in
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(99, 99, 99))
        // 1_000_000
        var seed = VoxelArray(bounds: bounds, initialValue: 0)
        for idx in bounds.y(0 ... 0).indices {
            seed[idx] = 1
        }

        let engine = CASimulationEngine(SingleIntStorage(seed), rules: [
            .eval(name: "inc", scope: .all, IncrementSingleInt()),
            CASimulationRule.swap(name: "flip", SwapInt())
        ])

        for _ in benchmark.scaledIterations {
            benchmark.startMeasurement()
            engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
            benchmark.stopMeasurement()
        }
    }
}
