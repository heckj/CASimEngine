public import Voxels

/// A cellular automata simulation engine.
///
/// Initialize the engine with a collection of voxels and rules that operate on those voxels.
/// Increment the simulation synchronously using ``tick(deltaTime:)``, or asynchronously using
/// ``tick(deltaTime:)``.
///
/// During operation, the engine runs the rules in the order that you provide them when creating the engine.
///
/// For testing a single rule against a collection of voxels, use ``CASimRule/evaluate(index:voxels:deltaTime:)``.
/// To synchronously test a rule against a collection of voxels, use ``diagnosticEvaluate(deltaTime:rule:)`` which returns a list of ``CADiagnostic`` from the processing.
public final class CADirectSimEngine<T: Sendable> {
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

    var activeVoxels: Set<VoxelIndex>
    let bounds: VoxelBounds

    let rules: [any CASimulationRule<T>]

    /// An asynchronous stream of diagnostics generated from your rules.
    public let diagnosticStream: AsyncStream<CADiagnostic>
    let _diagnosticContinuation: AsyncStream<CADiagnostic>.Continuation

    public init(_ seed: any VoxelAccessible<T>, rules: [any CASimulationRule<T>]) {
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
        activeVoxels = []
        for idx in bounds {
            activeVoxels.insert(idx)
        }
        self.rules = rules
        (diagnosticStream, _diagnosticContinuation) = AsyncStream.makeStream(of: CADiagnostic.self)
    }

    deinit {
        _diagnosticContinuation.finish()
    }

    /// Synchronously runs all rules, in order, updating the simulations voxels.
    /// - Parameter deltaTime: The time step to use for the rule evaluation.
    public func tick(deltaTime: Duration) {
        for r in rules {
            evaluate(deltaTime: deltaTime, rule: r)
        }
    }

    /// Synchronously runs a rule you provide using the time step you provide.
    /// - Parameters:
    ///   - deltaTime: The time step to use for the rule evaluation.
    ///   - rule: The cellular automata rule to process.
    func evaluate(deltaTime: Duration, rule: some CASimulationRule<T>) {
        var newHash: VoxelArray<T>
        let oldHash: VoxelArray<T>
        if activeStorage {
            newHash = _voxelStorage1
            oldHash = _voxelStorage2
        } else {
            newHash = _voxelStorage2
            oldHash = _voxelStorage1
        }
        var newActives: Set<VoxelIndex> = []

        switch rule.scope {
        case .active:
            for i in activeVoxels {
                let result = rule.evaluate(index: i, readVoxels: oldHash, writeVoxels: &newHash, deltaTime: deltaTime)
                if result.updatedVoxel {
                    newActives.insert(i)
                }
                if let diagnostic = result.diagnostic {
                    _diagnosticContinuation.yield(
                        CADiagnostic(index: i, rule: rule.name, messages: diagnostic.messages))
                }
            }
            activeVoxels = newActives
        case .all:
            for i in oldHash.bounds {
                let result = rule.evaluate(index: i, readVoxels: oldHash, writeVoxels: &newHash, deltaTime: deltaTime)
                if result.updatedVoxel {
                    newActives.insert(i)
                }
                if let diagnostic = result.diagnostic {
                    _diagnosticContinuation.yield(
                        CADiagnostic(index: i, rule: rule.name, messages: diagnostic.messages))
                }
            }
            activeVoxels = newActives
        case let .bounds(scopeBounds):
            // DOES NOT influence set of actives
            assert(oldHash.bounds.contains(scopeBounds))
            for i in scopeBounds {
                let result = rule.evaluate(index: i, readVoxels: oldHash, writeVoxels: &newHash, deltaTime: deltaTime)
                if let diagnostic = result.diagnostic {
                    _diagnosticContinuation.yield(
                        CADiagnostic(index: i, rule: rule.name, messages: diagnostic.messages))
                }
            }
        case let .index(singleIndex):
            // DOES NOT influence set of actives
            let result = rule.evaluate(index: singleIndex, readVoxels: oldHash, writeVoxels: &newHash, deltaTime: deltaTime)
            if let diagnostic = result.diagnostic {
                _diagnosticContinuation.yield(
                    CADiagnostic(index: singleIndex, rule: rule.name, messages: diagnostic.messages))
            }
        case let .collection(indices):
            for i in indices {
                let result = rule.evaluate(index: i, readVoxels: oldHash, writeVoxels: &newHash, deltaTime: deltaTime)
                if let diagnostic = result.diagnostic {
                    _diagnosticContinuation.yield(
                        CADiagnostic(index: i, rule: rule.name, messages: diagnostic.messages))
                }
            }
        }

        if activeStorage {
            _voxelStorage1 = newHash
        } else {
            _voxelStorage2 = newHash
        }
        activeStorage.toggle()
    }

    /// Synchronously runs a rule you provide using the time step you provide.
    /// - Parameters:
    ///   - deltaTime: The time step to use for the rule evaluation.
    ///   - rule: The cellular automata rule to process.
    /// - Returns: A collection of diagnostic messages from the rule.
    @discardableResult public func diagnosticEvaluate(deltaTime: Duration, rule: some CASimulationRule<T>) -> [CADiagnostic] {
        var diagnostics: [CADiagnostic] = []

        var newHash: VoxelArray<T>
        let oldHash: VoxelArray<T>
        if activeStorage {
            newHash = _voxelStorage1
            oldHash = _voxelStorage2
        } else {
            newHash = _voxelStorage2
            oldHash = _voxelStorage1
        }
        var newActives: Set<VoxelIndex> = []

        switch rule.scope {
        case .active:
            for i in activeVoxels {
                let result = rule.evaluate(index: i, readVoxels: oldHash, writeVoxels: &newHash, deltaTime: deltaTime)
                if result.updatedVoxel {
                    newActives.insert(i)
                }
                if let diagnostic = result.diagnostic {
                    diagnostics.append(
                        CADiagnostic(index: i, rule: rule.name, messages: diagnostic.messages))
                }
            }
            activeVoxels = newActives
        case .all:
            for i in oldHash.bounds {
                let result = rule.evaluate(index: i, readVoxels: oldHash, writeVoxels: &newHash, deltaTime: deltaTime)
                if result.updatedVoxel {
                    newActives.insert(i)
                }
                if let diagnostic = result.diagnostic {
                    diagnostics.append(
                        CADiagnostic(index: i, rule: rule.name, messages: diagnostic.messages))
                }
            }
            activeVoxels = newActives
        case let .bounds(scopeBounds):
            // DOES NOT influence set of actives
            assert(oldHash.bounds.contains(scopeBounds))
            for i in scopeBounds {
                let result = rule.evaluate(index: i, readVoxels: oldHash, writeVoxels: &newHash, deltaTime: deltaTime)
                if let diagnostic = result.diagnostic {
                    diagnostics.append(
                        CADiagnostic(index: i, rule: rule.name, messages: diagnostic.messages))
                }
            }
        case let .index(singleIndex):
            // DOES NOT influence set of actives
            let result = rule.evaluate(index: singleIndex, readVoxels: oldHash, writeVoxels: &newHash, deltaTime: deltaTime)
            if let diagnostic = result.diagnostic {
                diagnostics.append(
                    CADiagnostic(index: singleIndex, rule: rule.name, messages: diagnostic.messages))
            }
        case let .collection(indices):
            for i in indices {
                let result = rule.evaluate(index: i, readVoxels: oldHash, writeVoxels: &newHash, deltaTime: deltaTime)
                if let diagnostic = result.diagnostic {
                    _diagnosticContinuation.yield(
                        CADiagnostic(index: i, rule: rule.name, messages: diagnostic.messages))
                }
            }
        }

        if activeStorage {
            _voxelStorage1 = newHash
        } else {
            _voxelStorage2 = newHash
        }
        activeStorage.toggle()
        return diagnostics
    }
}