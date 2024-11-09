public import Voxels

/// The set of voxels to process.
public enum CARuleScope: Sendable {
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
