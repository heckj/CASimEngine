public import Voxels

/// The location of a cell and it's neighbors within a voxel bounds.
///
/// Neighbors outside the bounds are represented as `nil`.
public struct CAPosition: Sendable {
    /// The linear index of the cell to be processed.
    public let cell: Int
    /// The voxel index of the cell to be processed.
    public let voxelIndex: VoxelIndex
    /// The bounds of the simulation.
    public let bounds: VoxelBounds
    
    // Manhattan distance 1 neighbors
    // 'l' loosely means left, along the negative axis, and 'r' as right, along the positive axis.
    
    /// The linear index of the neighbor at `x-1` (to the left along the `x` axis) of the current cell.
    public let xl: Int?

    /// The linear index of the neighbor at `x+1` (to the right along the `x` axis) of the current cell.
    public let xr: Int?
    
    /// The linear index of the neighbor at `y-1` (to the left along the `y` axis) of the current cell.
    public let yl: Int?

    /// The linear index of the neighbor at `y+1` (to the right along the `y` axis) of the current cell.
    public let yr: Int?
    
    /// The linear index of the neighbor at `z-1` (to the left along the `z` axis) of the current cell.
    public let zl: Int?

    /// The linear index of the neighbor at `z+1` (to the right along the `z` axis) of the current cell.
    public let zr: Int?

//    // Manhattan distance 2 neighbors
//    let xl_yl: Int
//    let xr_yl: Int
//    let xl_yr: Int
//    let xr_yr: Int
//    let xl_zl: Int
//    let xr_zl: Int
//    let xl_zr: Int
//    let xr_zr: Int
    
    /// Creates a new Neighbors instance.
    /// - Parameters:
    ///   - linearIndex: The linear index location of the cell.
    ///   - bounds: The bounds of the simulation.
    public init(linearIndex: Int, bounds: VoxelBounds) {
        self.bounds = bounds
        self.cell = linearIndex
        self.voxelIndex = bounds._unchecked_delinearize(linearIndex)
        
        self.xl = currentVoxelIndex.x > 0 ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(-1, 0, 0))) : nil
        
        self.xr = currentVoxelIndex.x < self.bounds.max.x ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(1, 0, 0))) : nil
        
        self.yl = currentVoxelIndex.y > 0 ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, -1, 0))) : nil

        self.yr = currentVoxelIndex.y < self.bounds.max.y ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, 1, 0))) : nil
    
        self.zl =  currentVoxelIndex.z > 0 ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, 0, -1))) : nil
        
        self.zr =  currentVoxelIndex.z < self.bounds.max.z ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, 0, 1))) : nil
    }
}
