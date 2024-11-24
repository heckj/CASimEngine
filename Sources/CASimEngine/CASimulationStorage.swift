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

    /// An uninitialized default cell value.
    var uninitializedDefault: T { get }

    /// The state of the storage reassembled into a VoxelArray.
    var current: VoxelArray<T> { get }

    /// The state of an individual voxel reassembled from storage at the given linear index.
    func voxelAt(_ index: Int) -> T
}

public extension CASimulationStorage {
    @inlinable
    var current: VoxelArray<T> {
        var newArray = VoxelArray<T>(bounds: bounds, initialValue: uninitializedDefault)
        for i in 0 ..< bounds.size {
            let voxelIndex = bounds._unchecked_delinearize(i)
            newArray[voxelIndex] = voxelAt(i)
        }
        return newArray
    }
}
