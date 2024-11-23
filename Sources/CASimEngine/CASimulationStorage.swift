public import Voxels

/// A type that represents the storage for a cellular automata simulation.
public protocol CASimulationStorage<T> {
    /// The type that encompasses all the properties for import or export.
    associatedtype T: Sendable
    /// The bounds of the simulation.
    var bounds: VoxelBounds { get }
    /// Creates a new storage instance for the simulation.
    /// - Parameter voxels: the VoxelArray collection to initialize the storage.
    init(_ voxels: VoxelArray<T>)
    /// Returns a collection of VoxelUpdate the represent the changed values in the simulation.
    func changes() -> [VoxelUpdate<T>]

    /// The state of the storage reassembled into a VoxelArray.
    var current: VoxelArray<T> { get }
}
