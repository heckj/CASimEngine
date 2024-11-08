public import Voxels

/// The set of voxels within the collection that the engine processes.
///
/// The default scope is ``active``, which represents the set of voxels that were updated by the previous rule.
public enum CARuleProcessingScope: Sendable {
    /// All voxels in the engine.
    case all
    /// The set of voxels that were updated by the previous rule.
    case active
    /// A single voxel index.
    case index(VoxelIndex)
    /// A range of voxels.
    case bounds(VoxelBounds)
    /// A specified collection of indices
    case collection([VoxelIndex])
}
