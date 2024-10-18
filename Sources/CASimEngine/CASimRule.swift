public import Voxels

/// A type the describes an individual rule.
///
/// Create an instance of `CASimRule` providing a ``name``, optional ``scope``, and ``closure`` that is called to process an individual voxel.
///
/// The closure provides the index location of the voxel array to process, the collection of voxels, and a delta time provided for the simulation. With the closure, create and return a ``CAResult`` that includes the new voxel data, if it's updated by the rule.
///
/// ### Testing Rules
///
/// For testing a single rule against a collection of voxels, use ``CASimEngine/CASimEngine/tick(deltaTime:rule:)`` and consume a stream of
/// ``CADiagnostic`` from ``CASimEngine/CASimEngine/diagnosticStream``.
/// To synchronously test a rule against a collection of voxels, use ``CASimEngine/CASimEngine/diagnosticEvaluate(deltaTime:rule:)`` which returns a list of ``CADiagnostic`` from the processing.
///
/// To test a rule against a single voxel within a collection, use ``CASimRule/evaluate(index:voxels:deltaTime:)``, which returns ``CADetailedDiagnostic`` for in-depth inspection of before and after values.

public struct CASimRule<T: Sendable>: Sendable {
    public typealias CASimRuleClosure = @Sendable (VoxelIndex, VoxelHash<T>, Duration) -> CAResult<T>
    public let name: String
    public let scope: CARuleProcessingScope
    public let closure: CASimRuleClosure

    public init(name: String, scope: CARuleProcessingScope = .active, closure: @escaping CASimRuleClosure) {
        self.name = name
        self.scope = scope
        self.closure = closure
    }

    public func evaluate(index: VoxelIndex, voxels: VoxelHash<T>, deltaTime: Duration) -> CADetailedDiagnostic<T>? {
        guard let initialValue = voxels[index] else { return nil
        }
        let processResult: CAResult<T> = closure(index, voxels, deltaTime)

        return CADetailedDiagnostic(index: index,
                                    rule: name,
                                    initialValue: initialValue,
                                    finalValue: processResult.updatedVoxel,
                                    messages: processResult.messages)
    }
}
