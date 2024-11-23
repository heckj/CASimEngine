@testable internal import CASimEngine
internal import Voxels
import XCTest

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
        // 0.427 - Xcode 16.2 beta 3
    }
}
