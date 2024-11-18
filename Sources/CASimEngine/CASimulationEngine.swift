public import Voxels

// #if canImport(os)
import os

// #endif

let subsystem = "CASimulation"

/// A cellular automata simulation engine.
///
/// Initialize the engine with a collection of voxels and rules that operate on those voxels.
/// Call ``tick(deltaTime:)`` to increment the simulation, and read out the values using ``voxels``.
///
/// During operation, the engine runs the rules in the order that you provide them when creating the engine.
///
/// To test a rule against a collection of voxels, use ``diagnosticEvaluate(deltaTime:rule:)`` which returns a list of ``CADetailedDiagnostic`` for each voxel updated during its evaluation.
public final class CASimulationEngine<T: Sendable> {
    // #if canImport(os)
    let logger: Logger = .init(subsystem: subsystem, category: "Persistence")
    let signposter: OSSignposter
    // #endif

    // flip-flop writing in the voxel storage collections
    // as the CA simulation progresses. This keeps allocations
    // to a bare minimum.
    var _voxelStorage1: VoxelArray<T>
    var _voxelStorage2: VoxelArray<T>
    var activeStorage: Bool

    /// The collection of voxels
    public var voxels: VoxelArray<T> {
        activeStorage ? _voxelStorage1 : _voxelStorage2
    }

    var _actives: [VoxelIndex] = []

    let bounds: VoxelBounds

    let rules: [any CASimulationRule<T>]

    /// An asynchronous stream of diagnostics generated from your rules.
    public let diagnosticStream: AsyncStream<CADiagnostic>
    let _diagnosticContinuation: AsyncStream<CADiagnostic>.Continuation

    public init(_ seed: any VoxelAccessible<T>, rules: [any CASimulationRule<T>]) {
        // #if canImport(os)
        signposter = OSSignposter(logger: logger)
        // #endif

        guard let firstValueFound = seed.first else {
            fatalError("No values found in voxel collection")
        }
        // initialize array
        _voxelStorage1 = VoxelArray(bounds: seed.bounds, initialValue: firstValueFound)
        bounds = seed.bounds
        // copy in from the seed
        for idx in seed.bounds {
            _voxelStorage1[idx] = seed[idx]
        }
        _voxelStorage2 = _voxelStorage1
        activeStorage = true
        // set all voxels as initially active
        _actives = Array(_voxelStorage1.bounds)
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
//        #if canImport(os)
        let signpostId = signposter.makeSignpostID()
        let state = signposter.beginInterval("tick", id: signpostId)
//        #endif
        for r in rules {
            evaluate(deltaTime: deltaTime, rule: r)
//            #if canImport(os)
            signposter.emitEvent("rule", id: signpostId, "\(r.name)")
//            #endif
        }
//        #if canImport(os)
        signposter.endInterval("tick", state)
//        #endif
    }

    /// Run a rule against the collection of voxels, updating the simulation.
    /// Diagnostics from the rule, if any, are emitted to ``diagnosticStream``.
    ///
    /// - Parameters:
    ///   - deltaTime: The time step to use for the rule evaluation.
    ///   - rule: The cellular automata rule to process.
    func evaluate(deltaTime: Duration, rule: some CASimulationRule<T>) {
//        #if canImport(os)
        let signpostId = signposter.makeSignpostID()
        let state = signposter.beginInterval("tick.evaluate", id: signpostId)
//        #endif
        var newVoxels: VoxelArray<T>
        let currentVoxels: VoxelArray<T>
        var newActives: [VoxelIndex] = []
        if activeStorage {
            newVoxels = _voxelStorage1
            currentVoxels = _voxelStorage2
        } else {
            newVoxels = _voxelStorage2
            currentVoxels = _voxelStorage1
        }

        switch rule.scope {
        case .active:
            for i in _actives {
                guard var temp = currentVoxels[i] else { continue }
                let result = rule.evaluate(index: i, readVoxels: currentVoxels, newVoxel: &temp, deltaTime: deltaTime)
                if result.updatedVoxel {
                    newActives.append(i)
                    newVoxels.set(i, newValue: temp)
                }
                if let diagnostic = result.diagnostic {
                    _diagnosticContinuation.yield(
                        CADiagnostic(index: i, rule: rule.name, messages: diagnostic.messages))
                }
            }
            _actives = newActives
        case .all:
            for i in currentVoxels.bounds {
                guard var temp = currentVoxels[i] else { continue }
                let result = rule.evaluate(index: i, readVoxels: currentVoxels, newVoxel: &temp, deltaTime: deltaTime)
                if result.updatedVoxel {
                    newActives.append(i)
                    newVoxels.set(i, newValue: temp)
                }
                if let diagnostic = result.diagnostic {
                    _diagnosticContinuation.yield(
                        CADiagnostic(index: i, rule: rule.name, messages: diagnostic.messages))
                }
            }
            _actives = newActives
        }

        if activeStorage {
            _voxelStorage1 = newVoxels
        } else {
            _voxelStorage2 = newVoxels
        }
        activeStorage.toggle()
//        #if canImport(os)
        signposter.endInterval("tick.evaluate", state)
//        #endif
    }

    /// Run a rule against the collection of voxels, updating the simulation and collecting diagnostics as it processes.
    /// - Parameters:
    ///   - deltaTime: The time step to use for the rule evaluation.
    ///   - rule: The cellular automata rule to process.
    /// - Returns: A list of ``CADetailedDiagnostic``, one for each voxel updated.
    @discardableResult public func diagnosticEvaluate(deltaTime: Duration, rule: some CASimulationRule<T>) -> [CADetailedDiagnostic<T>] {
        var diagnostics: [CADetailedDiagnostic<T>] = []

        var newVoxels: VoxelArray<T>
        let currentVoxels: VoxelArray<T>
        var newActives: [VoxelIndex] = []
        if activeStorage {
            newVoxels = _voxelStorage1
            currentVoxels = _voxelStorage2
        } else {
            newVoxels = _voxelStorage2
            currentVoxels = _voxelStorage1
        }

        switch rule.scope {
        case .active:
            for i in _actives {
                guard var temp = currentVoxels[i] else { continue }
                let result = rule.evaluate(index: i, readVoxels: currentVoxels, newVoxel: &temp, deltaTime: deltaTime)
                if result.updatedVoxel {
                    newActives.append(i)
                    newVoxels[i] = temp
                    diagnostics.append(
                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: currentVoxels[i], finalValue: newVoxels[i], messages: result.diagnostic?.messages ?? [])
                    )
                } else {
                    diagnostics.append(
                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: currentVoxels[i], finalValue: nil, messages: result.diagnostic?.messages ?? [])
                    )
                }
            }
            _actives = newActives
        case .all:
            for i in currentVoxels.bounds {
                guard var temp = currentVoxels[i] else { continue }
                let result = rule.evaluate(index: i, readVoxels: currentVoxels, newVoxel: &temp, deltaTime: deltaTime)
                if result.updatedVoxel {
                    newActives.append(i)
                    newVoxels[i] = temp
                    diagnostics.append(
                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: currentVoxels[i], finalValue: newVoxels[i], messages: result.diagnostic?.messages ?? [])
                    )
                } else {
                    diagnostics.append(
                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: currentVoxels[i], finalValue: nil, messages: result.diagnostic?.messages ?? [])
                    )
                }
            }
            _actives = newActives
        }

        if activeStorage {
            _voxelStorage1 = newVoxels
        } else {
            _voxelStorage2 = newVoxels
        }
        activeStorage.toggle()
        return diagnostics
    }
}
