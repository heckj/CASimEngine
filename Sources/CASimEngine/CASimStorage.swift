public import Voxels

#if canImport(os)
    import os
#endif

public protocol StorageProtocol<T> {
    associatedtype T: Sendable
    var bounds: VoxelBounds { get }
    init(_ voxels: VoxelArray<T>)
    func changes() -> [VoxelUpdate<T>]
}

// storage<T>
// -> storage
// -> rules
// MARK: Example

public struct FluidSimStorage: StorageProtocol {
    public let bounds: VoxelBounds
    
    public var solid: Array<Float> = []
    public var fluidMass: Array<Float> = []
    public var fluidVelX: Array<Float> = []
    public var fluidVelY: Array<Float> = []
    public var fluidVelZ: Array<Float> = []
    public var fluidPressure: Array<Float> = []
    
    public init(_ voxels: VoxelArray<MultiResourceCell>) {
        bounds = voxels.bounds
        for i in 0..<bounds.size {
            //let voxelIndex = bounds._unchecked_delinearize(i)
            solid[i] = voxels[i].primaryTypeVolume
            fluidMass[i] = voxels[i].liquidVolume
            fluidVelX[i] = voxels[i].flowX
            fluidVelY[i] = voxels[i].flowY
            fluidVelZ[i] = voxels[i].flowZ
            fluidPressure[i] = voxels[i].pressure
        }
                
    }
    
    public func changes() -> [VoxelUpdate<T>] {
        return []
    }
}
