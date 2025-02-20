public import Voxels

public extension VoxelBounds {
    /// Returns the Manhattan distance 1 neighbors that are within the bounds of a linear index position you provide.
    /// - Parameter linearIndex: The index location around which to find neighbors within the bounds.
    /// - Returns: The list of linear indices of the neighbors.
    ///
    /// Neighbors that are outside the bounds are not included in the resulting array of linear indices.
    @inline(__always)
    func neighbors(of linearIndex: Int) -> [Int] {
        let currentVoxelIndex: VoxelIndex = _unchecked_delinearize(linearIndex)

        let offsets = [
            VoxelIndex(-1, 0, 0),
            VoxelIndex(0, -1, 0),
            VoxelIndex(0, 0, -1),
            VoxelIndex(1, 0, 0),
            VoxelIndex(0, 1, 0),
            VoxelIndex(0, 0, 1),
        ]

        let results: [Int] = offsets.compactMap { voxelOffset in
            let neighborIndex = currentVoxelIndex.adding(voxelOffset)
            if self.contains(neighborIndex) {
                return self._unchecked_linearize(neighborIndex)
            } else {
                return nil
            }
        }

        return results
    }
}
