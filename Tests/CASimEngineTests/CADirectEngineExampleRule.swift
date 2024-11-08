internal import Voxels
internal import CASimEngine

struct DirectNoEffectRule<T: Sendable>: CASimulationRule {
    public typealias VoxelType = T

    public let name: String = "NoEffectKeepActive"
    public let scope: CARuleProcessingScope = .active

    public func evaluate(index _: Voxels.VoxelIndex, readVoxels _: Voxels.VoxelArray<T>, writeVoxels _: inout Voxels.VoxelArray<T>, deltaTime _: Duration) -> CADirectRuleResult {
        // all actives stay active
        .noUpdate
    }
}
