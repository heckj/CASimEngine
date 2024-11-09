@testable internal import CASimEngine
internal import Voxels
import XCTest // import Testing for 6.0...

final class EngineTests: XCTestCase {
    func testSimplestRule() throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(99, 99, 99))
        var seed = VoxelArray(bounds: bounds, initialValue: 0)
        for idx in bounds.y(0 ... 0).indices {
            seed[idx] = 1
        }

        XCTAssertEqual(seed.bounds.indices.count, 100 * 100 * 100)

        // let rule = DirectNoEffectRule<Int>()

        let engine = CASimulationEngine(seed, rules: [IncrementRule()])

        XCTAssertEqual(engine.activeVoxels.count, 100 * 100 * 100)

        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        XCTAssertEqual(engine.activeVoxels.count, 1_000_000)

        measure {
            engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        }
        // loosely 0.882 seconds
        // roughly 17% faster than the closure based approach
    }
}
