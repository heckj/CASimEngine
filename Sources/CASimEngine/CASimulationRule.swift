public import Voxels

/// A type that processes voxels within a cellular automata simulation.
public protocol CASimulationRule<VoxelType>: Sendable {
    /// The type of voxel the rule processes.
    associatedtype VoxelType
    /// The name of the rule
    var name: String { get }
    /// The set of voxels to process.
    var scope: CARuleScope { get }
    
    /// The function that the simulation engine calls to process a voxel.
    /// - Parameters:
    ///   - index: The index of the voxel within the simulation.
    ///   - readVoxels: The set of voxels that hold the current state.
    ///   - writeVoxels: The set of voxels to hold updated state.
    ///   - deltaTime: The change in time in the simulation.
    /// - Returns: A result that indicates if the evaluation changed a voxel, and optionally diagnostic messages from this rule.
    func evaluate(index: VoxelIndex, readVoxels: VoxelArray<VoxelType>, writeVoxels: inout VoxelArray<VoxelType>, deltaTime: Duration) -> CARuleResult
}
