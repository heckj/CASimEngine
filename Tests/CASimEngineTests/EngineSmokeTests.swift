@testable internal import CASimEngine
internal import Voxels
import XCTest // import Testing for 6.0...

final class EngineSmokeTests: XCTestCase {
    func testSimplestRule() throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(99, 99, 99))
        var seed = VoxelArray(bounds: bounds, initialValue: 0)
        for idx in bounds.y(0 ... 0).indices {
            seed[idx] = 1
        }

        XCTAssertEqual(seed.bounds.indices.count, 100 * 100 * 100)

        // let rule = DirectNoEffectRule<Int>()

        let engine = CASimulationEngine(seed, rules: [IncrementAllRule()])

        XCTAssertEqual(engine.activeVoxels.count, 100 * 100 * 100)

        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        XCTAssertEqual(engine.activeVoxels.count, 1_000_000)

        measure {
            engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        }
        // standard test time: loosely 1.013 seconds (debug build)
        // in profiling, it's showing ~313ms per iteration (release build)
    }
}
