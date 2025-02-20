public import CASimEngine
public import Voxels

public enum CellType: Sendable {
    public typealias RawValue = UInt8
    case open // available for fluid to move in and out of
    case solid // blocked - wall or other solid around which fluid moves
}

public struct FluidSimCell: Sendable, Hashable {
    public var type: CellType
    public var volume: Float = 0 // UnitVolume - 0...1

    // for free flowing liquids
    public var pressure: Float = 0
    public var flowX: Float = 0 // momentum of movement in +X direction (kg * m / sec)
    public var flowY: Float = 0 // momentum of movement in +Y direction (kg * m / sec)
    public var flowZ: Float = 0 // momentum of movement in +Z direction (kg * m / sec)

    public init(resource: CellType, unitFill: Float = 1.0) {
        type = resource
        volume = unitFill
    }

    public static let open = Self(resource: .open, unitFill: 0.0)
    public static let solid = Self(resource: .solid, unitFill: 1.0)
}

extension FluidSimCell {
    func isStatic() -> Bool {
        type == .solid
    }
}

// pretty sure I want this to be a reference type...
public struct FluidSimStorage: CASimulationStorage {
    public typealias T = FluidSimCell
    public let bounds: VoxelBounds
    public let uninitializedDefault = FluidSimCell.open

    public var fluidMass: [Float] = []
    public var fluidVelX: [Float] = []
    public var fluidVelY: [Float] = []
    public var fluidVelZ: [Float] = []
    public var fluidPressure: [Float] = []

    @inlinable
    public init(_ voxels: VoxelArray<T>) {
        bounds = voxels.bounds
        for i in 0 ..< bounds.size {
            // let voxelIndex = bounds._unchecked_delinearize(i)
            fluidMass[i] = voxels[i].volume
            fluidVelX[i] = voxels[i].flowX
            fluidVelY[i] = voxels[i].flowY
            fluidVelZ[i] = voxels[i].flowZ
            fluidPressure[i] = voxels[i].pressure
        }
    }

    @inlinable
    public func voxelAt(_ index: Int) -> T {
        var instance = uninitializedDefault
        instance.volume = fluidMass[index]
        instance.flowX = fluidVelX[index]
        instance.flowY = fluidVelY[index]
        instance.flowZ = fluidVelZ[index]
        instance.pressure = fluidPressure[index]
        return instance
    }

    @inlinable
    public var current: VoxelArray<T> {
        var newArray = VoxelArray<T>(bounds: bounds, initialValue: .open)
        for i in 0 ..< bounds.size {
            let voxelIndex = bounds._unchecked_delinearize(i)
            newArray[voxelIndex] = voxelAt(i)
        }
        return newArray
    }
}
