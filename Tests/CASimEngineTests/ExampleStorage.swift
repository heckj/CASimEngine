public import CASimEngine
public import Voxels

// MARK: Example StorageProtocol

public struct FluidSimStorage: CASimulationStorage {
    public typealias T = MultiResourceCell
    public let bounds: VoxelBounds

    public var solid: [Float] = []
    public var fluidMass: [Float] = []
    public var fluidVelX: [Float] = []
    public var fluidVelY: [Float] = []
    public var fluidVelZ: [Float] = []
    public var fluidPressure: [Float] = []

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

    public func changes() -> [VoxelUpdate<T>] {
        []
    }

    public var current: VoxelArray<T> {
        var newArray = VoxelArray<T>(bounds: bounds, initialValue: .air)
        for i in 0 ..< bounds.size {
            let voxelIndex = bounds._unchecked_delinearize(i)
            var instance = MultiResourceCell.air
            instance.primaryTypeVolume = solid[i]
            instance.liquidVolume = fluidMass[i]
            instance.flowX = fluidVelX[i]
            instance.flowY = fluidVelY[i]
            instance.flowZ = fluidVelZ[i]
            instance.pressure = fluidPressure[i]
            newArray[voxelIndex] = instance
        }
        return newArray
    }
}
