public import Voxels

public protocol CASimulationRule<VoxelType>: Sendable {
    associatedtype VoxelType
    var name: String { get }
    var scope: CARuleProcessingScope { get }

    func evaluate(index: VoxelIndex, readVoxels: VoxelArray<VoxelType>, writeVoxels: inout VoxelArray<VoxelType>, deltaTime: Duration) -> CADirectRuleResult
}
