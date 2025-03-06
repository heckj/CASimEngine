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
        ])

        XCTAssertEqual(engine._actives.count, 100 * 100 * 100)

        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        XCTAssertEqual(engine._actives.count, 1_000_000)

        // verify the values have incremented once
        XCTAssertEqual(engine.current[VoxelIndex(0, 0, 0)], 2)
        XCTAssertEqual(engine.current[VoxelIndex(1, 1, 1)], 1)

        measure {
            engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        }
        // standard test time: loosely 0.518 seconds (debug build)
        // 0.427 - Xcode 16.2 beta 3
        // 0.991 sec - Xcode 16.3 beta 2 (debug build)

        // adding changes slowed this down to: 0.615, 0.555 with pre-allocating storage
    }

    func testStateGenerationTiming() throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(99, 99, 99))
        var seed = VoxelArray(bounds: bounds, initialValue: Float(0))
        for idx in bounds.y(0 ... 0).indices {
            seed[idx] = 1
        }

        let engine = CASimulationEngine(SingleFloatStorage(seed), rules: [
            .eval(name: "increment", scope: .all, IncrementSingleFloat()),
        ])
        engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))

        measure {
            let state = engine.current
            XCTAssertEqual(state.bounds, bounds)
        }
        // standard test time: loosely 0.278 seconds (debug build)
        // 0.289 - Xcode 16.2 beta 3 (debug build)
    }

    func testChangesTiming() throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(99, 99, 99))
        var seed = VoxelArray(bounds: bounds, initialValue: Float(0))
        for idx in bounds.y(0 ... 0).indices {
            seed[idx] = 1
        }

        let engine = CASimulationEngine(SingleFloatStorage(seed), rules: [
            .eval(name: "increment", scope: .all, IncrementSingleFloat()),
        ])

        for _ in 0 ... 10 {
            engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        }

        measure {
            let state = engine.changes()
            XCTAssertEqual(state.count, 1_000_000)
        }
        // standard test time: loosely 0.250 seconds (debug build)
    }

    func testDiagnosticEvaluate() throws {
        let bounds = VoxelBounds(min: .init(0, 0, 0), max: .init(99, 99, 99))
        let seed = VoxelArray(bounds: bounds, initialValue: Float(15))
        let engine = CASimulationEngine(SingleFloatStorage(seed), rules: [
            .eval(name: "increment", scope: .all, IncrementSingleFloat()),
        ])

        for _ in 0 ... 10 {
            engine.tick(deltaTime: Duration(secondsComponent: 1, attosecondsComponent: 0))
        }

        let check = engine.diagnosticEvaluate(deltaTime: .seconds(0.1), scope: .all, stepName: "increment", step: IncrementSingleFloat())
        XCTAssertEqual(check.count, 1_000_000)
    }
}
