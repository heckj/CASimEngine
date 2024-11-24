public import Voxels

#if canImport(os)
    import os
#endif

/// A cellular automata simulation engine.
///
/// The simulation engine (``CASimEngine``) processes the rules in the order you provide them on each iteration of ``CASimulationEngine/tick(deltaTime:)``.
/// Call ``tick(deltaTime:)`` to increment the simulation, and read out the current state from the property ``current``, or a collection of the updated values from the function ``changes()``.
///
/// Initialize the engine with a storage container that conforms to ``CASimulationStorage``, that loads collection of voxels, and rules that operate on those voxels.
///
/// The engine maintains two copies of the storage type you provide to "ping-pong" updates while advancing the simulation.
/// During the processing, the first storage buffer represents the current state of the simulation, and the second storage buffer is where you should write the updated state.
/// At the end of the sequence of rules, the engine swaps the two storage buffers, incrementing the simulation.
///
/// To test a rule against a collection of voxels, use ``diagnosticEvaluate(deltaTime:scope:stepName:step:)`` which returns a list of ``CADetailedDiagnostic`` for each voxel updated during its evaluation.
public final class CASimulationEngine<T: CASimulationStorage> {
    #if canImport(os)
        let signposter: OSSignposter
    #endif

    // arrays of structs (instead of struct of arrays, would could be VoxelArray<T>)
    var storage0: T
    var storage1: T

    var _actives: [VoxelIndex] = []

    var changed: Set<Int>

    let bounds: VoxelBounds

    let rules: [CASimulationRule<T>]

    /// An asynchronous stream of diagnostics generated from your rules.
    public let diagnosticStream: AsyncStream<CADiagnostic>
    let _diagnosticContinuation: AsyncStream<CADiagnostic>.Continuation

    public var current: VoxelArray<T.T> {
        storage0.current
    }

    /// Returns a collection of VoxelUpdate the represent the changed values in the simulation.
    public func changes() -> [VoxelUpdate<T.T>] {
        var collected: [VoxelUpdate<T.T>] = []
        for linearIndex in changed {
            let voxelIndex = bounds._unchecked_delinearize(linearIndex)
            collected.append(.init(index: voxelIndex, value: storage0.voxelAt(linearIndex)))
        }
        return collected
    }

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
        changed = Set<Int>(minimumCapacity: bounds.size)
        (diagnosticStream, _diagnosticContinuation) = AsyncStream.makeStream(of: CADiagnostic.self)
    }

    deinit {
        _diagnosticContinuation.finish()
    }

    /// Runs the rules, in order, against the collection of voxels, updating the simulation.
    /// Diagnostics from the rule, if any, are emitted to ``diagnosticStream``.
    /// - Parameter deltaTime: The time step to use for the rule evaluation.
    public func tick(deltaTime: Duration) {
        changed = Set<Int>(minimumCapacity: bounds.size)
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
    func evaluate(deltaTime: Duration, scope: CARuleScope, stepName: String, step: some EvaluateStep<T>) {
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
                let result = step.evaluate(linearIndex: linearIndex, deltaTime: deltaTime, storage0: storage0, storage1: &storage1)
                if result.updatedVoxel {
                    newActives.append(i)
                    changed.insert(linearIndex)
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
                let result = step.evaluate(linearIndex: i, deltaTime: deltaTime, storage0: storage0, storage1: &storage1)
                let voxelIndex = bounds._unchecked_delinearize(i)
                if result.updatedVoxel {
                    newActives.append(voxelIndex)
                    changed.insert(i)
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

    /// Run a rule against the collection of voxels, updating the simulation and collecting diagnostics as it processes.
    /// - Parameters:
    ///   - deltaTime: The time step to use for the rule evaluation.
    ///   - scope: The scope for the step's evaluation.
    ///   - stepName: The name of the step.
    ///   - step: The step to evaluate.
    /// - Returns: A list of ``CADetailedDiagnostic``, one for each voxel updated.
    @discardableResult public func diagnosticEvaluate(deltaTime: Duration, scope: CARuleScope, stepName: String, step: some EvaluateStep<T>) -> [CADetailedDiagnostic<T.T>] {
        var diagnostics: [CADetailedDiagnostic<T.T>] = []
        changed = Set<Int>(minimumCapacity: bounds.size)

        switch scope {
        case .active:
            for i in _actives {
                let linearIndex: Int = bounds._unchecked_linearize(i)
                // guard var temp = currentVoxels[i] else { continue }
                let result = step.evaluate(linearIndex: linearIndex, deltaTime: deltaTime, storage0: storage0, storage1: &storage1)
                if result.updatedVoxel {
                    changed.insert(linearIndex)
                    diagnostics.append(
                        CADetailedDiagnostic(index: i, rule: stepName, initialValue: storage0.voxelAt(linearIndex), finalValue: storage1.voxelAt(linearIndex), messages: result.diagnostic?.messages ?? [])
                    )
                } else {
                    diagnostics.append(
                        CADetailedDiagnostic(index: i, rule: stepName, initialValue: storage0.voxelAt(linearIndex), finalValue: nil, messages: result.diagnostic?.messages ?? [])
                    )
                }
            }

        case .all:
            for i in 0 ..< bounds.size {
                // guard var temp = currentVoxels[i] else { continue }
                let result = step.evaluate(linearIndex: i, deltaTime: deltaTime, storage0: storage0, storage1: &storage1)
                let voxelIndex = bounds._unchecked_delinearize(i)
                if result.updatedVoxel {
                    changed.insert(i)
                    diagnostics.append(
                        CADetailedDiagnostic(index: voxelIndex, rule: stepName, initialValue: storage0.voxelAt(i), finalValue: storage1.voxelAt(i), messages: result.diagnostic?.messages ?? [])
                    )
                } else {
                    diagnostics.append(
                        CADetailedDiagnostic(index: voxelIndex, rule: stepName, initialValue: storage0.voxelAt(i), finalValue: nil, messages: result.diagnostic?.messages ?? [])
                    )
                }
            }
        }
        return diagnostics
    }
}
