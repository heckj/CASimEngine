@testable internal import CASimEngine
internal import Voxels
import XCTest // import Testing for 6.0...

final class EngineFunctionalTests: XCTestCase {
    func testInitialActiveSet() throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(9, 9, 9))
        let seed = VoxelArray(bounds: bounds, initialValue: 0)
        XCTAssertEqual(seed.bounds.indices.count, 10 * 10 * 10)
        let engine = CASimulationEngine(seed, rules: [])
        XCTAssertEqual(engine.activeVoxels.count, 10 * 10 * 10)
    }

    func testActiveScope() throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(9, 9, 9))
        let seed = VoxelArray(bounds: bounds, initialValue: 0)
        let engine = CASimulationEngine(seed, rules: [IncrementActiveRule()])

        XCTAssertEqual(engine.activeVoxels.count, 10 * 10 * 10)

        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        XCTAssertEqual(engine.activeVoxels.count, 1000)
    }

    func testActiveScopeNoEffect() throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(9, 9, 9))
        let seed = VoxelArray(bounds: bounds, initialValue: 0)
        let engine = CASimulationEngine(seed, rules: [NoEffectRule()])

        XCTAssertEqual(engine.activeVoxels.count, 10 * 10 * 10)

        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        XCTAssertEqual(engine.activeVoxels.count, 0)
    }

    func testAllScope() throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(9, 9, 9))
        let seed = VoxelArray(bounds: bounds, initialValue: 0)
        let engine = CASimulationEngine(seed, rules: [IncrementAllRule()])

        XCTAssertEqual(engine.activeVoxels.count, 10 * 10 * 10)
        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        XCTAssertEqual(engine.activeVoxels.count, 10 * 10 * 10)
    }
}
