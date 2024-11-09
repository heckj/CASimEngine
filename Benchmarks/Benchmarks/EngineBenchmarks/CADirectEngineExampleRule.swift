import CASimEngine
import Voxels

struct IncrementRule: CASimulationRule {
    public typealias VoxelType = Int

    public let name: String = "NoEffectKeepActive"
    public let scope: CARuleScope = .all

    public func evaluate(index: Voxels.VoxelIndex, readVoxels: Voxels.VoxelArray<VoxelType>, writeVoxels: inout VoxelType, deltaTime _: Duration) -> CARuleResult {
        // all actives stay active
        writeVoxels = (readVoxels[index] ?? 0) + 1
        return .indexUpdated
    }
}
