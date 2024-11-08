@testable internal import CASimEngine
internal import Voxels
import XCTest // import Testing for 6.0...

final class EngineTests: XCTestCase {
    func testSimplestRule() async throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(9, 9, 9))
        var seed = VoxelArray(bounds: bounds, initialValue: 0)
        for idx in bounds.y(0 ... 0).indices {
            seed[idx] = 1
        }

        XCTAssertEqual(seed.bounds.indices.count, 10 * 10 * 10)

        let rule = DirectNoEffectRule<Int>()

        let engine = CADirectSimEngine(seed, rules: [rule])

        XCTAssertEqual(engine.activeVoxels.count, 10 * 10 * 10)

        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        XCTAssertEqual(engine.activeVoxels.count, 0)

        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
    }

    func testSimplestRuleClosureEngine() async throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(9, 9, 9))
        var seed = VoxelArray(bounds: bounds, initialValue: 0)
        for idx in bounds.y(0 ... 0).indices {
            seed[idx] = 1
        }

        XCTAssertEqual(seed.bounds.indices.count, 10 * 10 * 10)

        let rule = CASimRule<Int>(name: "hi", scope: .active) { idx, _, _ in
            CAResult<Int>(index: idx, updatedVoxel: nil)
        }

        let engine = CASimEngine(seed, rules: [rule])

        XCTAssertEqual(engine.activeVoxels.count, 10 * 10 * 10)

        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        XCTAssertEqual(engine.activeVoxels.count, 0)

        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
    }
}
