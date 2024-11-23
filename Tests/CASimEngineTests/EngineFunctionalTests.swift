@testable internal import CASimEngine
internal import Voxels
import XCTest // import Testing for 6.0...

final class EngineFunctionalTests: XCTestCase {
    func testInitialActiveSet() throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(9, 9, 9))
        let seed = VoxelArray(bounds: bounds, initialValue: 0)
        XCTAssertEqual(seed.bounds.indices.count, 10 * 10 * 10)
        let engine = CASimulationEngine(SingleIntStorage(seed), rules: [])
        XCTAssertEqual(engine._actives.count, 10 * 10 * 10)
    }

    func testActiveScope() throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(9, 9, 9))
        let seed = VoxelArray(bounds: bounds, initialValue: 0)
        let engine = CASimulationEngine(SingleIntStorage(seed), rules: [
            .eval(name: "inc", scope: .active, IncrementSingleInt()),
        ])

        XCTAssertEqual(engine._actives.count, 10 * 10 * 10)

        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        XCTAssertEqual(engine._actives.count, 1000)
    }

    func testActiveScopeNoEffect() throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(9, 9, 9))
        let seed = VoxelArray(bounds: bounds, initialValue: 0)
        let engine = CASimulationEngine(SingleIntStorage(seed), rules: [
            .eval(name: "noop", scope: .active, NoEffect()),
        ])

        XCTAssertEqual(engine._actives.count, 10 * 10 * 10)

        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        XCTAssertEqual(engine._actives.count, 0)
    }

    func testAllScope() throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(9, 9, 9))
        let seed = VoxelArray(bounds: bounds, initialValue: 0)
        let engine = CASimulationEngine(SingleIntStorage(seed), rules: [
            .eval(name: "inc", scope: .all, IncrementSingleInt()),
        ])

        XCTAssertEqual(engine._actives.count, 10 * 10 * 10)
        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        XCTAssertEqual(engine._actives.count, 10 * 10 * 10)
    }

    func testCurrentValue() throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(9, 9, 9))
        let seed = VoxelArray(bounds: bounds, initialValue: 0)
        let engine = CASimulationEngine(SingleIntStorage(seed), rules: [
            .eval(name: "inc", scope: .active, IncrementSingleInt()),
        ])
        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))

        let expected = VoxelArray(bounds: bounds, initialValue: 2)
        // XCTAssertEqual(engine.current, expected)

        // workaround for now...
        let current = engine.current
        for i in bounds {
            XCTAssertEqual(current[i], expected[i])
        }
    }
}
