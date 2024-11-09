internal import Voxels
internal import CASimEngine

struct DirectNoEffectRule<T: Sendable>: CASimulationRule {
    public typealias VoxelType = T

    public let name: String = "NoEffectKeepActive"
    public let scope: CARuleScope = .active

    public func evaluate(index _: Voxels.VoxelIndex, readVoxels _: Voxels.VoxelArray<T>, newVoxel _: inout T, deltaTime _: Duration) -> CARuleResult {
        // all actives stay active
        .noUpdate
    }
}

struct IncrementRule: CASimulationRule {
    public typealias VoxelType = Int

    public let name: String = "NoEffectKeepActive"
    public let scope: CARuleScope = .all

    public func evaluate(index: Voxels.VoxelIndex, readVoxels: Voxels.VoxelArray<VoxelType>, newVoxel: inout VoxelType, deltaTime _: Duration) -> CARuleResult {
        // all actives stay active
        newVoxel = (readVoxels[index] ?? 0) + 1
        return .indexUpdated
    }
}
