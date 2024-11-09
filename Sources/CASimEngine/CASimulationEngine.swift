public import Voxels

/// A cellular automata simulation engine.
///
/// Initialize the engine with a collection of voxels and rules that operate on those voxels.
/// Call ``tick(deltaTime:)`` to increment the simulation, and read out the values using ``voxels``.
///
/// During operation, the engine runs the rules in the order that you provide them when creating the engine.
///
/// To test a rule against a collection of voxels, use ``diagnosticEvaluate(deltaTime:rule:)`` which returns a list of ``CADetailedDiagnostic`` for each voxel updated during its evaluation.
public final class CASimulationEngine<T: Sendable> {
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

    /// Runs the rules, in order, against the collection of voxels, updating the simulation.
    /// Diagnostics from the rule, if any, are emitted to ``diagnosticStream``.
    /// - Parameter deltaTime: The time step to use for the rule evaluation.
    public func tick(deltaTime: Duration) {
        for r in rules {
            evaluate(deltaTime: deltaTime, rule: r)
        }
    }

    /// Run a rule against the collection of voxels, updating the simulation.
    /// Diagnostics from the rule, if any, are emitted to ``diagnosticStream``.
    ///
    /// - Parameters:
    ///   - deltaTime: The time step to use for the rule evaluation.
    ///   - rule: The cellular automata rule to process.
    func evaluate(deltaTime: Duration, rule: some CASimulationRule<T>) {
        var newVoxels: VoxelArray<T>
        let currentVoxels: VoxelArray<T>
        if activeStorage {
            newVoxels = _voxelStorage1
            currentVoxels = _voxelStorage2
        } else {
            newVoxels = _voxelStorage2
            currentVoxels = _voxelStorage1
        }
        var newActives: Set<VoxelIndex> = []

        switch rule.scope {
        case .active:
            for i in activeVoxels {
                let result = rule.evaluate(index: i, readVoxels: currentVoxels, writeVoxels: &newVoxels, deltaTime: deltaTime)
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
            for i in currentVoxels.bounds {
                let result = rule.evaluate(index: i, readVoxels: currentVoxels, writeVoxels: &newVoxels, deltaTime: deltaTime)
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
            assert(currentVoxels.bounds.contains(scopeBounds))
            for i in scopeBounds {
                let result = rule.evaluate(index: i, readVoxels: currentVoxels, writeVoxels: &newVoxels, deltaTime: deltaTime)
                if let diagnostic = result.diagnostic {
                    _diagnosticContinuation.yield(
                        CADiagnostic(index: i, rule: rule.name, messages: diagnostic.messages))
                }
            }
        case let .index(singleIndex):
            // DOES NOT influence set of actives
            let result = rule.evaluate(index: singleIndex, readVoxels: currentVoxels, writeVoxels: &newVoxels, deltaTime: deltaTime)
            if let diagnostic = result.diagnostic {
                _diagnosticContinuation.yield(
                    CADiagnostic(index: singleIndex, rule: rule.name, messages: diagnostic.messages))
            }
        case let .collection(indices):
            for i in indices {
                let result = rule.evaluate(index: i, readVoxels: currentVoxels, writeVoxels: &newVoxels, deltaTime: deltaTime)
                if let diagnostic = result.diagnostic {
                    _diagnosticContinuation.yield(
                        CADiagnostic(index: i, rule: rule.name, messages: diagnostic.messages))
                }
            }
        }

        if activeStorage {
            _voxelStorage1 = newVoxels
        } else {
            _voxelStorage2 = newVoxels
        }
        activeStorage.toggle()
    }

    /// Run a rule against the collection of voxels, updating the simulation and collecting diagnostics as it processes.
    /// - Parameters:
    ///   - deltaTime: The time step to use for the rule evaluation.
    ///   - rule: The cellular automata rule to process.
    /// - Returns: A list of ``CADetailedDiagnostic``, one for each voxel updated.
    @discardableResult public func diagnosticEvaluate(deltaTime: Duration, rule: some CASimulationRule<T>) -> [CADetailedDiagnostic<T>] {
        var diagnostics: [CADetailedDiagnostic<T>] = []

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
                    diagnostics.append(
                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: oldHash[i], finalValue: newHash[i], messages: result.diagnostic?.messages ?? [])
                    )
                } else {
                    diagnostics.append(
                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: oldHash[i], finalValue: nil, messages: result.diagnostic?.messages ?? [])
                    )
                }
            }
            activeVoxels = newActives
        case .all:
            for i in oldHash.bounds {
                let result = rule.evaluate(index: i, readVoxels: oldHash, writeVoxels: &newHash, deltaTime: deltaTime)
                if result.updatedVoxel {
                    newActives.insert(i)
                    diagnostics.append(
                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: oldHash[i], finalValue: newHash[i], messages: result.diagnostic?.messages ?? [])
                    )
                } else {
                    diagnostics.append(
                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: oldHash[i], finalValue: nil, messages: result.diagnostic?.messages ?? [])
                    )
                }
            }
            activeVoxels = newActives
        case let .bounds(scopeBounds):
            // DOES NOT influence set of actives
            assert(oldHash.bounds.contains(scopeBounds))
            for i in scopeBounds {
                let result = rule.evaluate(index: i, readVoxels: oldHash, writeVoxels: &newHash, deltaTime: deltaTime)
                if result.updatedVoxel {
                    diagnostics.append(
                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: oldHash[i], finalValue: newHash[i], messages: result.diagnostic?.messages ?? [])
                    )
                } else {
                    diagnostics.append(
                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: oldHash[i], finalValue: nil, messages: result.diagnostic?.messages ?? [])
                    )
                }
            }
        case let .index(singleIndex):
            // DOES NOT influence set of actives
            let result = rule.evaluate(index: singleIndex, readVoxels: oldHash, writeVoxels: &newHash, deltaTime: deltaTime)
            if result.updatedVoxel {
                diagnostics.append(
                    CADetailedDiagnostic(index: singleIndex, rule: rule.name, initialValue: oldHash[singleIndex], finalValue: newHash[singleIndex], messages: result.diagnostic?.messages ?? [])
                )
            } else {
                diagnostics.append(
                    CADetailedDiagnostic(index: singleIndex, rule: rule.name, initialValue: oldHash[singleIndex], finalValue: nil, messages: result.diagnostic?.messages ?? [])
                )
            }
        case let .collection(indices):
            for i in indices {
                let result = rule.evaluate(index: i, readVoxels: oldHash, writeVoxels: &newHash, deltaTime: deltaTime)
                if result.updatedVoxel {
                    diagnostics.append(
                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: oldHash[i], finalValue: newHash[i], messages: result.diagnostic?.messages ?? [])
                    )
                } else {
                    diagnostics.append(
                        CADetailedDiagnostic(index: i, rule: rule.name, initialValue: oldHash[i], finalValue: nil, messages: result.diagnostic?.messages ?? [])
                    )
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
