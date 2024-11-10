internal import Voxels
internal import CASimEngine

struct NoEffectRule<T: Sendable>: CASimulationRule {
    public typealias VoxelType = T

    public let name: String = "NoEffect"
    public let scope: CARuleScope = .active

    public func evaluate(index _: Voxels.VoxelIndex, readVoxels _: Voxels.VoxelArray<T>, newVoxel _: inout T, deltaTime _: Duration) -> CARuleResult {
        // all actives go inactive
        .noUpdate
    }
}

struct UpdateNoChangeRule<T: Sendable>: CASimulationRule {
    public typealias VoxelType = T

    public let name: String = "UpdateNoChange"
    public let scope: CARuleScope = .active

    public func evaluate(index: Voxels.VoxelIndex, readVoxels: Voxels.VoxelArray<T>, newVoxel: inout T, deltaTime _: Duration) -> CARuleResult {
        // all actives stay active

        // this makes an explicit copy from the old array into new location, which is redundant
        newVoxel = readVoxels[index] ?? newVoxel
        return .indexUpdated
    }
}

struct IncrementAllRule: CASimulationRule {
    public typealias VoxelType = Int

    public let name: String = "IncrementAll"
    public let scope: CARuleScope = .all

    public func evaluate(index: Voxels.VoxelIndex, readVoxels: Voxels.VoxelArray<VoxelType>, newVoxel: inout VoxelType, deltaTime _: Duration) -> CARuleResult {
        // all actives stay active
        newVoxel = (readVoxels[index] ?? 0) + 1
        return .indexUpdated
    }
}

struct IncrementActiveRule: CASimulationRule {
    public typealias VoxelType = Int

    public let name: String = "IncrementActive"
    public let scope: CARuleScope = .active

    public func evaluate(index: Voxels.VoxelIndex, readVoxels: Voxels.VoxelArray<VoxelType>, newVoxel: inout VoxelType, deltaTime _: Duration) -> CARuleResult {
        // all actives stay active
        newVoxel = (readVoxels[index] ?? 0) + 1
        return .indexUpdated
    }
}
