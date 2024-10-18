public import Voxels

/// A cellular automata simulation engine.
///
/// Initialize the engine with a collection of voxels and rules that operate on those voxels.
/// Increment the simulation synchronously using ``tick(deltaTime:)-4dohs``, or asynchronously using
/// ``tick(deltaTime:)-xlyj``.
///
/// During operation, the engine runs the rules in the order that you provide them when creating the engine.
///
/// For testing a single rule against a collection of voxels, use ``tick(deltaTime:rule:)`` and consume a stream of
/// ``CADiagnostic`` from ``diagnosticStream``.
/// To synchronously test a rule against a collection of voxels, use ``diagnosticEvaluate(deltaTime:rule:)`` which returns a list of ``CADiagnostic`` from the processing.
///
/// To test a rule against a single voxel within a collection, use ``CASimRule/evaluate(index:voxels:deltaTime:)``, which returns ``CADetailedDiagnostic`` for in-depth inspection of before and after values.
public final class CASimEngine<T: Sendable> {
    // flip-flop writing in the voxel storage collections
    // as the CA simulation progresses. This keeps allocations
    // to a bare minimum.
    var _voxelStorage1: VoxelHash<T>
    var _voxelStorage2: VoxelHash<T>
    var activeStorage: Bool

    /// The collection of voxels
    public var voxels: VoxelHash<T> {
        activeStorage ? _voxelStorage1 : _voxelStorage2
    }

    var activeVoxels: Set<VoxelIndex>
    let bounds: VoxelBounds

    let rules: [CASimRule<T>]
    /// An asynchronous stream of diagnostics generated from your rules.
    public let diagnosticStream: AsyncStream<CADiagnostic>
    let _diagnosticContinuation: AsyncStream<CADiagnostic>.Continuation

    public init(_ seed: VoxelHash<T>, rules: [CASimRule<T>]) {
        _voxelStorage1 = seed
        _voxelStorage2 = _voxelStorage1
        bounds = seed.bounds
        activeStorage = true
        // set all voxels as initially active
        activeVoxels = []
        for idx in bounds.indices {
            activeVoxels.insert(idx)
        }
        self.rules = rules
        (diagnosticStream, _diagnosticContinuation) = AsyncStream.makeStream(of: CADiagnostic.self)
    }

    deinit {
        _diagnosticContinuation.finish()
    }

    /// Asynchronously runs all rules, in order, updating the simulations voxels.
    /// - Parameter deltaTime: The time step to use for the rule evaluation.
    ///
    /// If the rule creates any diagnostic messages, those are included in the results that stream
    /// to `diagnosticStream`.
    public func tick(deltaTime: Duration) async {
        for r in rules {
            await tick(deltaTime: deltaTime, rule: r)
        }
    }

    /// An asynchronous processing of a single rule.
    ///
    /// If the rule creates any diagnostic messages, those are included in the results that stream
    /// to `diagnosticStream`.
    ///
    /// - Parameters:
    ///   - deltaTime: The time step to use for the rule evaluation.
    ///   - rule: The cellular automata rule to process.
    public func tick(deltaTime: Duration, rule: CASimRule<T>) async {
        // make a reference copy to update for the storage to poke into
        // activeStorage is true: _voxelStorage1 is the set getting updated and _voxelStorage2 is the
        // read-only version to read from.
        var newHash: VoxelHash<T>
        let oldHash: VoxelHash<T>
        if activeStorage {
            newHash = _voxelStorage1
            oldHash = _voxelStorage2
        } else {
            newHash = _voxelStorage2
            oldHash = _voxelStorage1
        }
        var newActives: Set<VoxelIndex> = []

        let asyncActives = await withTaskGroup(of: CAResult<T>.self, returning: Set<VoxelIndex>.self) { taskgroup in
            switch rule.scope {
            case .active:
                for i in activeVoxels {
                    taskgroup.addTask {
                        rule.closure(i, oldHash, deltaTime)
                    }
                }
            case .all:
                for i in oldHash.bounds.indices {
                    taskgroup.addTask {
                        rule.closure(i, oldHash, deltaTime)
                    }
                }
            case let .bounds(scopeBounds):
                // DOES NOT influence set of actives
                assert(oldHash.bounds.contains(scopeBounds))
                for i in scopeBounds.indices {
                    taskgroup.addTask {
                        rule.closure(i, oldHash, deltaTime)
                    }
                }
            case let .index(singleIndex):
                // DOES NOT influence set of actives
                taskgroup.addTask {
                    rule.closure(singleIndex, oldHash, deltaTime)
                }
            }

            for await processResult in taskgroup {
                if let updatedVoxel = processResult.updatedVoxel {
                    newHash[processResult.index] = updatedVoxel
                    newActives.insert(processResult.index)
                }
                if !processResult.messages.isEmpty {
                    self._diagnosticContinuation.yield(CADiagnostic(index: processResult.index, rule: rule.name, messages: processResult.messages))
                }
            }
            return newActives
        }

        // only update the list of active voxels if the rule processed based on active or all voxels.
        switch rule.scope {
        case .active, .all:
            activeVoxels = asyncActives
        case .bounds, .index:
            break
        }

        if activeStorage {
            _voxelStorage1 = newHash
        } else {
            _voxelStorage2 = newHash
        }
        activeStorage.toggle()
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
    func evaluate(deltaTime: Duration, rule: CASimRule<T>) {
        var newHash: VoxelHash<T>
        let oldHash: VoxelHash<T>
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
                let processResult: CAResult<T> = rule.closure(i, oldHash, deltaTime)
                if let updatedVoxel = processResult.updatedVoxel {
                    newActives.insert(i)
                    newHash[i] = updatedVoxel
                }
                if !processResult.messages.isEmpty {
                    _diagnosticContinuation.yield(
                        CADiagnostic(index: processResult.index, rule: rule.name, messages: processResult.messages))
                }
            }
            activeVoxels = newActives
        case .all:
            for i in oldHash.bounds.indices {
                let processResult: CAResult<T> = rule.closure(i, oldHash, deltaTime)
                if let updatedVoxel = processResult.updatedVoxel {
                    newActives.insert(i)
                    newHash[i] = updatedVoxel
                }
                if !processResult.messages.isEmpty {
                    _diagnosticContinuation.yield(
                        CADiagnostic(index: processResult.index, rule: rule.name, messages: processResult.messages))
                }
            }
            activeVoxels = newActives
        case let .bounds(scopeBounds):
            // DOES NOT influence set of actives
            assert(oldHash.bounds.contains(scopeBounds))
            for i in scopeBounds.indices {
                let processResult: CAResult<T> = rule.closure(i, oldHash, deltaTime)
                if let updatedVoxel = processResult.updatedVoxel {
                    newHash[i] = updatedVoxel
                }
                if !processResult.messages.isEmpty {
                    _diagnosticContinuation.yield(
                        CADiagnostic(index: processResult.index, rule: rule.name, messages: processResult.messages))
                }
            }
        case let .index(singleIndex):
            // DOES NOT influence set of actives
            let processResult: CAResult<T> = rule.closure(singleIndex, oldHash, deltaTime)
            if let updatedVoxel = processResult.updatedVoxel {
                newHash[singleIndex] = updatedVoxel
            }
            if !processResult.messages.isEmpty {
                _diagnosticContinuation.yield(
                    CADiagnostic(index: processResult.index, rule: rule.name, messages: processResult.messages))
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
    @discardableResult public func diagnosticEvaluate(deltaTime: Duration, rule: CASimRule<T>) -> [CADiagnostic] {
        var diagnostics: [CADiagnostic] = []

        var newHash: VoxelHash<T>
        let oldHash: VoxelHash<T>
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
                let processResult: CAResult<T> = rule.closure(i, oldHash, deltaTime)
                if let updatedVoxel = processResult.updatedVoxel {
                    newActives.insert(i)
                    newHash[i] = updatedVoxel
                }
                if !processResult.messages.isEmpty {
                    diagnostics.append(
                        CADiagnostic(index: processResult.index, rule: rule.name, messages: processResult.messages))
                }
            }
            activeVoxels = newActives
        case .all:
            for i in oldHash.bounds.indices {
                let processResult: CAResult<T> = rule.closure(i, oldHash, deltaTime)
                if let updatedVoxel = processResult.updatedVoxel {
                    newActives.insert(i)
                    newHash[i] = updatedVoxel
                }
                if !processResult.messages.isEmpty {
                    diagnostics.append(
                        CADiagnostic(index: processResult.index, rule: rule.name, messages: processResult.messages))
                }
            }
            activeVoxels = newActives
        case let .bounds(scopeBounds):
            // DOES NOT influence set of actives
            assert(oldHash.bounds.contains(scopeBounds))
            for i in scopeBounds.indices {
                let processResult: CAResult<T> = rule.closure(i, oldHash, deltaTime)
                if let updatedVoxel = processResult.updatedVoxel {
                    newHash[i] = updatedVoxel
                }
                if !processResult.messages.isEmpty {
                    diagnostics.append(
                        CADiagnostic(index: processResult.index, rule: rule.name, messages: processResult.messages))
                }
            }
        case let .index(singleIndex):
            // DOES NOT influence set of actives
            let processResult: CAResult<T> = rule.closure(singleIndex, oldHash, deltaTime)
            if let updatedVoxel = processResult.updatedVoxel {
                newHash[singleIndex] = updatedVoxel
            }
            if !processResult.messages.isEmpty {
                diagnostics.append(
                    CADiagnostic(index: processResult.index, rule: rule.name, messages: processResult.messages))
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

    // rule flow?
    // gravity/drop - apply if flowing/moving/active - checking adhesion to side neighbors, and above
    // gravity/flow - apply if flowing/moving/active
    // heat diffusion - apply everywhere
    // if state-change from ∂-heat, add to active

    // StarsReach uses 9 bytes per voxel index
    // 1 - temperature at index (8 remaining)
    // 1 - type of resource (allow 255 variants) (7 remaining)
    // 1 - mass of type (6 remaining)
    // 3 x 2 - velocity (FP) in X, Y, and Z vectorsxs
}
