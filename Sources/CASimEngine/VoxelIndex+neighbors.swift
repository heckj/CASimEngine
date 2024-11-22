public import Voxels

public extension VoxelIndex {
    /// Returns the manhattan neighbors with a distance of one from this index.
    @inlinable
    func neighbors1() -> [VoxelIndex] {
        [
            adding(VoxelIndex(1, 0, 0)),
            adding(VoxelIndex(-1, 0, 0)),
            adding(VoxelIndex(0, 1, 0)),
            adding(VoxelIndex(0, -1, 0)),
            adding(VoxelIndex(0, 0, 1)),
            adding(VoxelIndex(0, 0, -1)),
        ]
    }

    /// Returns the manhattan neighbors with a distance of two from this index.
    @inlinable
    func neighbors2() -> [VoxelIndex] {
        var neighbors: [VoxelIndex] = []
        for i in x - 1 ... x + 1 {
            for j in y - 1 ... y + 1 {
                for k in z - 1 ... z + 1 {
                    let new = VoxelIndex(i, j, k)
                    let distance = VoxelIndex.manhattan_distance(from: self, to: new)
                    if distance == 1 || distance == 2 {
                        neighbors.append(new)
                    }
                }
            }
        }
        neighbors.append(adding(VoxelIndex(2, 0, 0)))
        neighbors.append(adding(VoxelIndex(-2, 0, 0)))
        neighbors.append(adding(VoxelIndex(0, 2, 0)))
        neighbors.append(adding(VoxelIndex(0, -2, 0)))
        neighbors.append(adding(VoxelIndex(0, 0, 2)))
        neighbors.append(adding(VoxelIndex(0, 0, -2)))
        return neighbors
    }
}
