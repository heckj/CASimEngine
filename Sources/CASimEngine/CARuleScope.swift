/// The set of voxels for a rule to process.
///
/// When a voxel is updated by a rule, the engine adds it to an internal list of active voxels.
/// If a rule doesn't update a voxel, the voxel is removed from the list of active voxels.
public enum CARuleScope: Sendable {
    /// All voxels in the engine.
    case all
    /// The set of voxels that were updated by the previous rule.
    case active
}
