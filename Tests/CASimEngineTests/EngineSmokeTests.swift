@testable internal import CASimEngine
internal import Voxels
import XCTest // import Testing for 6.0...

final class EngineSmokeTests: XCTestCase {
    func testSimplestRule() throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(99, 99, 99))
        var seed = VoxelArray(bounds: bounds, initialValue: Float(0))
        for idx in bounds.y(0 ... 0).indices {
            seed[idx] = 1
        }

        XCTAssertEqual(seed.bounds.indices.count, 100 * 100 * 100)

        let engine = CASimulationEngine(SingleFloatStorage(seed), rules: [
            .eval(name: "increment", scope: .all, IncrementSingleFloat()),
            .swap(name: "swap", SwapSingleFloat()),
        ])

        XCTAssertEqual(engine._actives.count, 100 * 100 * 100)

        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        XCTAssertEqual(engine._actives.count, 1_000_000)

        measure {
            engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        }
        // standard test time: loosely 0.518 seconds (debug build)
        // in profiling, it's showing ~112ms per iteration (release build)

        // with the big ole reset to the code and storage, test time is: 0.436
        // and in profiling, it's down to 75ms per iteration
    }
}
