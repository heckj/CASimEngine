public import CASimEngine
public import Voxels

// MARK: Example StorageProtocol

public struct FluidSimStorage: CASimulationStorage {
    public typealias T = MultiResourceCell
    public let bounds: VoxelBounds
    public let uninitializedDefault = MultiResourceCell.air

    public var solid: [Float] = []
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
            solid[i] = voxels[i].primaryTypeVolume
            fluidMass[i] = voxels[i].liquidVolume
            fluidVelX[i] = voxels[i].flowX
            fluidVelY[i] = voxels[i].flowY
            fluidVelZ[i] = voxels[i].flowZ
            fluidPressure[i] = voxels[i].pressure
        }
    }

    @inlinable
    public func voxelAt(_ index: Int) -> MultiResourceCell {
        var instance = MultiResourceCell.air
        instance.primaryTypeVolume = solid[index]
        instance.liquidVolume = fluidMass[index]
        instance.flowX = fluidVelX[index]
        instance.flowY = fluidVelY[index]
        instance.flowZ = fluidVelZ[index]
        instance.pressure = fluidPressure[index]
        return instance
    }

    @inlinable
    public var current: VoxelArray<T> {
        var newArray = VoxelArray<T>(bounds: bounds, initialValue: .air)
        for i in 0 ..< bounds.size {
            let voxelIndex = bounds._unchecked_delinearize(i)
            newArray[voxelIndex] = voxelAt(i)
        }
        return newArray
    }
}
