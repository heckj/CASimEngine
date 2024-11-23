internal import Voxels

#if canImport(os)
    import os
#endif

/// A cellular automata simulation engine.
///
/// Initialize the engine with a collection of voxels and rules that operate on those voxels.
/// Call ``tick(deltaTime:)`` to increment the simulation, and read out the values using ``voxels``.
///
/// During operation, the engine runs the rules in the order that you provide them when creating the engine.
///
/// To test a rule against a collection of voxels, use ``diagnosticEvaluate(deltaTime:rule:)`` which returns a list of ``CADetailedDiagnostic`` for each voxel updated during its evaluation.
public final class CASimulationEngine<T: CASimulationStorage> {
    #if canImport(os)
        let signposter: OSSignposter
    #endif

    // arrays of structs (instead of struct of arrays, would could be VoxelArray<T>)
    var storage0: T
    var storage1: T

    var _actives: [VoxelIndex] = []

    let bounds: VoxelBounds

    let rules: [CASimulationRule<T>]

    /// An asynchronous stream of diagnostics generated from your rules.
    public let diagnosticStream: AsyncStream<CADiagnostic>
    let _diagnosticContinuation: AsyncStream<CADiagnostic>.Continuation

    var current: VoxelArray<T.T> {
        storage0.current
    }

//    public init(_ seed: any VoxelAccessible<T>, rules: [CASimulationRule<T>]) {
    public init(_ seed: T, rules: [CASimulationRule<T>]) {
        #if canImport(os)
            signposter = OSSignposter(subsystem: "Engine", category: .pointsOfInterest)
        #endif

        bounds = seed.bounds
        storage0 = seed
        storage1 = seed
        // set all voxels as initially active
        _actives = Array(storage0.bounds)
        self.rules = rules
        (diagnosticStream, _diagnosticContinuation) = AsyncStream.makeStream(of: CADiagnostic.self)
    }

    deinit {
        _diagnosticContinuation.finish()
    }

    /// Runs the rules, in order, against the collection of voxels, updating the simulation.
    /// Diagnostics from the rule, if any, are emitted to ``diagnosticStream``.
    /// - Parameter deltaTime: The time step to use for the rule evaluation.
    public func tick(deltaTime: Duration) {
        #if canImport(os)
            let signpostId = signposter.makeSignpostID()
            let state = signposter.beginInterval("tick", id: signpostId)
        #endif
        for r in rules {
            switch r {
            case let .swap(name, swapStep):
                swapStep.perform(storage0: &storage0, storage1: &storage1)
                #if canImport(os)
                    signposter.emitEvent("swap", id: signpostId, "\(name)")
                #endif
            case let .eval(name, scope, evaluateStep):
                evaluate(deltaTime: deltaTime, scope: scope, stepName: name, step: evaluateStep)
                #if canImport(os)
                    signposter.emitEvent("eval", id: signpostId, "\(name)")
                #endif
            }
        }
        swap(&storage0, &storage1)
        #if canImport(os)
            signposter.endInterval("tick", state)
        #endif
    }

    /// Run a rule against the collection of voxels, updating the simulation.
    /// Diagnostics from the rule, if any, are emitted to ``diagnosticStream``.
    ///
    /// - Parameters:
    ///   - deltaTime: The time step to use for the rule evaluation.
    ///   - rule: The cellular automata rule to process.
    func evaluate(deltaTime _: Duration, scope: CARuleScope, stepName: String, step: some EvaluateStep<T>) {
        #if canImport(os)
            let signpostId = signposter.makeSignpostID()
            let state = signposter.beginInterval("tick.evaluate", id: signpostId)
        #endif
        var newActives: [VoxelIndex] = []

        switch scope {
        case .active:
            for i in _actives {
                let linearIndex: Int = bounds._unchecked_linearize(i)
                // guard var temp = currentVoxels[i] else { continue }
                let result = step.evaluate(linearIndex: linearIndex, storage0: storage0, storage1: &storage1)
                if result.updatedVoxel {
                    newActives.append(i)
                }
                if let diagnostic = result.diagnostic {
                    _diagnosticContinuation.yield(
                        CADiagnostic(index: i, rule: stepName, messages: diagnostic.messages))
                }
            }
            _actives = newActives
        case .all:
            for i in 0 ..< bounds.size {
                // guard var temp = currentVoxels[i] else { continue }
                let result = step.evaluate(linearIndex: i, storage0: storage0, storage1: &storage1)
                let voxelIndex = bounds._unchecked_delinearize(i)
                if result.updatedVoxel {
                    newActives.append(voxelIndex)
                }
                if let diagnostic = result.diagnostic {
                    _diagnosticContinuation.yield(
                        CADiagnostic(index: voxelIndex, rule: stepName, messages: diagnostic.messages))
                }
            }
            _actives = newActives
        }

        #if canImport(os)
            signposter.endInterval("tick.evaluate", state)
        #endif
    }
//
//    /// Run a rule against the collection of voxels, updating the simulation and collecting diagnostics as it processes.
//    /// - Parameters:
//    ///   - deltaTime: The time step to use for the rule evaluation.
//    ///   - rule: The cellular automata rule to process.
//    /// - Returns: A list of ``CADetailedDiagnostic``, one for each voxel updated.
//    @discardableResult public func diagnosticEvaluate(deltaTime: Duration, rule: some CASimulationRule<T>) -> [CADetailedDiagnostic<T>] {
//        var diagnostics: [CADetailedDiagnostic<T>] = []
//
//        var newVoxels: VoxelArray<T>
//        let currentVoxels: VoxelArray<T>
//        var newActives: [VoxelIndex] = []
//        if activeStorage {
//            newVoxels = _voxelStorage1
//            currentVoxels = _voxelStorage2
//        } else {
//            newVoxels = _voxelStorage2
//            currentVoxels = _voxelStorage1
//        }
//
//        switch rule.scope {
//        case .active:
//            for i in _actives {
//                guard var temp = currentVoxels[i] else { continue }
//                let result = rule.evaluate(index: i, readVoxels: currentVoxels, newVoxel: &temp, deltaTime: deltaTime)
//                if result.updatedVoxel {
//                    newActives.append(i)
//                    newVoxels[i] = temp
//                    diagnostics.append(
//                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: currentVoxels[i], finalValue: newVoxels[i], messages: result.diagnostic?.messages ?? [])
//                    )
//                } else {
//                    diagnostics.append(
//                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: currentVoxels[i], finalValue: nil, messages: result.diagnostic?.messages ?? [])
//                    )
//                }
//            }
//            _actives = newActives
//        case .all:
//            for i in currentVoxels.bounds {
//                guard var temp = currentVoxels[i] else { continue }
//                let result = rule.evaluate(index: i, readVoxels: currentVoxels, newVoxel: &temp, deltaTime: deltaTime)
//                if result.updatedVoxel {
//                    newActives.append(i)
//                    newVoxels[i] = temp
//                    diagnostics.append(
//                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: currentVoxels[i], finalValue: newVoxels[i], messages: result.diagnostic?.messages ?? [])
//                    )
//                } else {
//                    diagnostics.append(
//                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: currentVoxels[i], finalValue: nil, messages: result.diagnostic?.messages ?? [])
//                    )
//                }
//            }
//            _actives = newActives
//        }
//
//        if activeStorage {
//            _voxelStorage1 = newVoxels
//        } else {
//            _voxelStorage2 = newVoxels
//        }
//        activeStorage.toggle()
//        return diagnostics
//    }
}
