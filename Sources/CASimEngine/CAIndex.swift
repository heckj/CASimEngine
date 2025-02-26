public import Voxels

/// The location of a cell and it's neighbors within a voxel bounds.
///
/// The linear index position of neighbors outside the bounds are represented as `-1`.
public struct CAIndex: Sendable {
    /// The linear index of the cell to be processed.
    public let index: Int
    /// The voxel index of the cell to be processed.
    public let voxelIndex: VoxelIndex
    /// The bounds of the simulation.
    public let bounds: VoxelBounds

    // Manhattan distance 1 neighbors
    // 'l' loosely means left, along the negative axis, and 'r' as right, along the positive axis.

    /// The linear index of the neighbor at `x-1` (to the left along the `x` axis) of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    public let xl: Int

    /// The linear index of the neighbor at `x+1` (to the right along the `x` axis) of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    public let xr: Int

    /// The linear index of the neighbor at `y-1` (to the left along the `y` axis) of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    public let yl: Int

    /// The linear index of the neighbor at `y+1` (to the right along the `y` axis) of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    public let yr: Int

    /// The linear index of the neighbor at `z-1` (to the left along the `z` axis) of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    public let zl: Int

    /// The linear index of the neighbor at `z+1` (to the right along the `z` axis) of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    public let zr: Int

    // Manhattan distance 2 neighbors

    /// The linear index of the neighbor at `x-1, y-1` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var xl_yl: Int {
        if voxelIndex.x < 1 || voxelIndex.y < 1 { return -1 }
        return bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(-1, -1, 0)))
    }

    /// The linear index of the neighbor at `x+1, y-1` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var xr_yl: Int {
        if voxelIndex.x == bounds.max.x || voxelIndex.y < 1 { return -1 }
        return bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(1, -1, 0)))
    }

    /// The linear index of the neighbor at `x-1, y+1` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var xl_yr: Int {
        if voxelIndex.x < 1 || voxelIndex.y == bounds.max.y { return -1 }
        return bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(-1, 1, 0)))
    }

    /// The linear index of the neighbor at `x+1, y+1` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var xr_yr: Int {
        if voxelIndex.x == bounds.max.x || voxelIndex.y == bounds.max.y { return -1 }
        return bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(1, 1, 0)))
    }

    /// The linear index of the neighbor at `x-1, z-1` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var xl_zl: Int {
        if voxelIndex.x < 1 || voxelIndex.z < 1 { return -1 }
        return bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(-1, 0, -1)))
    }

    /// The linear index of the neighbor at `x+1, z-1` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var xr_zl: Int {
        if voxelIndex.x == bounds.max.x || voxelIndex.z < 1 { return -1 }
        return bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(1, 0, -1)))
    }

    /// The linear index of the neighbor at `x-1, z+1` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var xl_zr: Int {
        if voxelIndex.x < 1 || voxelIndex.z == bounds.max.z { return -1 }
        return bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(-1, 0, 1)))
    }

    /// The linear index of the neighbor at `x+1, z+1` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var xr_zr: Int {
        if voxelIndex.x == bounds.max.x || voxelIndex.z == bounds.max.z { return -1 }
        return bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(1, 0, 1)))
    }

    /// The linear index of the neighbor at `y-1, z-1` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var yl_zl: Int {
        if voxelIndex.y < 1 || voxelIndex.z < 1 { return -1 }
        return bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, -1, -1)))
    }

    /// The linear index of the neighbor at `y+1, z-1` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var yr_zl: Int {
        if voxelIndex.y == bounds.max.x || voxelIndex.z < 1 { return -1 }
        return bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, 1, -1)))
    }

    /// The linear index of the neighbor at `y-1, z+1` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var yl_zr: Int {
        if voxelIndex.y < 1 || voxelIndex.z == bounds.max.z { return -1 }
        return bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, -1, 1)))
    }

    /// The linear index of the neighbor at `y+1, z+1` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var yr_zr: Int {
        if voxelIndex.y == bounds.max.x || voxelIndex.z == bounds.max.z { return -1 }
        return bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, 1, 1)))
    }

    /// The linear index of the neighbor at `x-2` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var xl2: Int {
        voxelIndex.x > 1 ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(-2, 0, 0))) : -1
    }

    /// The linear index of the neighbor at `x+2` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var xr2: Int {
        voxelIndex.x >= (bounds.max.x - 1) ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(2, 0, 0))) : -1
    }

    /// The linear index of the neighbor at `y-2` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var yl2: Int {
        voxelIndex.y > 1 ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, -2, 0))) : -1
    }

    /// The linear index of the neighbor at `y+2` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var yr2: Int {
        voxelIndex.y >= (bounds.max.y - 1) ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, 2, 0))) : -1
    }

    /// The linear index of the neighbor at `z-2` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var zl2: Int {
        voxelIndex.z > 1 ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, 0, -2))) : -1
    }

    /// The linear index of the neighbor at `z+2` of the current cell.
    ///
    /// If the neighbor is outside the bounds, the value is `-1`.
    @inline(__always) public var zr2: Int {
        voxelIndex.z >= (bounds.max.z - 1) ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, 0, 2))) : -1
    }

    /// Creates a new Neighbors instance.
    /// - Parameters:
    ///   - linearIndex: The linear index location of the cell.
    ///   - bounds: The bounds of the simulation.
    public init(linearIndex: Int, bounds: VoxelBounds) {
        self.bounds = bounds
        index = linearIndex
        voxelIndex = bounds._unchecked_delinearize(linearIndex)

        xl = voxelIndex.x > 0 ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(-1, 0, 0))) : -1

        xr = voxelIndex.x >= self.bounds.max.x ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(1, 0, 0))) : -1

        yl = voxelIndex.y > 0 ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, -1, 0))) : -1

        yr = voxelIndex.y >= self.bounds.max.y ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, 1, 0))) : -1

        zl = voxelIndex.z > 0 ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, 0, -1))) : -1

        zr = voxelIndex.z >= self.bounds.max.z ? bounds._unchecked_linearize(voxelIndex.adding(VoxelIndex(0, 0, 1))) : -1
    }
}
