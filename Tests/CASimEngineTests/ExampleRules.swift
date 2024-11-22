internal import CASimEngine
internal import Voxels

struct SingleIntStorage: StorageProtocol {
    public typealias T = Int
    let bounds: VoxelBounds

    var floatValue: [T] = []

    init(_ voxels: VoxelArray<T>) {
        bounds = voxels.bounds
        for i in 0 ..< bounds.size {
            // let voxelIndex = bounds._unchecked_delinearize(i)
            floatValue.append(voxels[i])
        }
    }

    func changes() -> [VoxelUpdate<T>] {
        []
    }
}

struct IncrementSingleInt: EvaluateStep {
    typealias StorageType = SingleIntStorage
    func evaluate(linearIndex: Int, storage0: StorageType, storage1: inout StorageType) -> CARuleResult {
        // need read access to storage0 and write access to storage1
        storage1.floatValue[linearIndex] = storage0.floatValue[linearIndex] + 1

        // computing the voxelIndex from the linear index
        // let _ = storage0.bounds._unchecked_delinearize(linearIndex)
        return .indexUpdated
    }
}

struct NoEffect: EvaluateStep {
    typealias StorageType = SingleIntStorage
    func evaluate(linearIndex _: Int, storage0 _: StorageType, storage1 _: inout StorageType) -> CARuleResult {
        .noUpdate
    }
}

struct SingleFloatStorage: StorageProtocol {
    public typealias T = Float
    let bounds: VoxelBounds

    var floatValue: [T] = []

    init(_ voxels: VoxelArray<T>) {
        bounds = voxels.bounds
        for i in 0 ..< bounds.size {
            // let voxelIndex = bounds._unchecked_delinearize(i)
            floatValue.append(voxels[i])
        }
    }

    func changes() -> [VoxelUpdate<T>] {
        []
    }
}

struct IncrementSingleFloat: EvaluateStep {
    typealias StorageType = SingleFloatStorage
    func evaluate(linearIndex: Int, storage0: StorageType, storage1: inout StorageType) -> CARuleResult {
        // need read access to storage0 and write access to storage1
        storage1.floatValue[linearIndex] = storage0.floatValue[linearIndex] + Float(1)

        // computing the voxelIndex from the linear index
        // let _ = storage0.bounds._unchecked_delinearize(linearIndex)
        return .indexUpdated
    }
}

struct FluidSimStorage: StorageProtocol {
    let bounds: VoxelBounds

    var solid: [Float] = []
    var fluidMass: [Float] = []
    var fluidVelX: [Float] = []
    var fluidVelY: [Float] = []
    var fluidVelZ: [Float] = []
    var fluidPressure: [Float] = []

    init(_ voxels: VoxelArray<MultiResourceCell>) {
        bounds = voxels.bounds
        for i in 0 ..< bounds.size {
            // let voxelIndex = bounds._unchecked_delinearize(i)
            solid.append(voxels[i].primaryTypeVolume)
            fluidMass.append(voxels[i].liquidVolume)
            fluidVelX.append(voxels[i].flowX)
            fluidVelY.append(voxels[i].flowY)
            fluidVelZ.append(voxels[i].flowZ)
            fluidPressure.append(voxels[i].pressure)
        }
    }

    func changes() -> [VoxelUpdate<T>] {
        []
    }
}

struct IncrementVelY: EvaluateStep {
    typealias StorageType = FluidSimStorage
    func evaluate(linearIndex: Int, storage0: StorageType, storage1: inout StorageType) -> CARuleResult {
        // need read access to storage0 and write access to storage1
        storage1.fluidVelY[linearIndex] = storage0.fluidVelY[linearIndex] + Float(1)

        // computing the voxelIndex from the linear index
        let _ = storage0.bounds._unchecked_delinearize(linearIndex)
        return .indexUpdated
    }
}

// internal import Voxels
//
// struct NoEffectRule<T: Sendable>: CASimulationRule {
//    public typealias VoxelType = T
//
//    public let name: String = "NoEffect"
//    public let scope: CARuleScope = .active
//
//    public func evaluate(index _: Voxels.VoxelIndex, readVoxels _: Voxels.VoxelArray<T>, newVoxel _: inout T, deltaTime _: Duration) -> CARuleResult {
//        // all actives go inactive
//        .noUpdate
//    }
// }
//
// struct UpdateNoChangeRule<T: Sendable>: CASimulationRule {
//    public typealias VoxelType = T
//
//    public let name: String = "UpdateNoChange"
//    public let scope: CARuleScope = .active
//
//    public func evaluate(index: Voxels.VoxelIndex, readVoxels: Voxels.VoxelArray<T>, newVoxel: inout T, deltaTime _: Duration) -> CARuleResult {
//        // all actives stay active
//
//        // this makes an explicit copy from the old array into new location, which is redundant
//        newVoxel = readVoxels[index] ?? newVoxel
//        return .indexUpdated
//    }
// }
//
// struct IncrementAllRule: CASimulationRule {
//    public typealias VoxelType = Int
//
//    public let name: String = "IncrementAll"
//    public let scope: CARuleScope = .all
//
//    public func evaluate(index: Voxels.VoxelIndex, readVoxels: Voxels.VoxelArray<VoxelType>, newVoxel: inout VoxelType, deltaTime _: Duration) -> CARuleResult {
//        // all actives stay active
//        newVoxel = (readVoxels[index] ?? 0) + 1
//        return .indexUpdated
//    }
// }
//
// struct IncrementActiveRule: CASimulationRule {
//    public typealias VoxelType = Int
//
//    public let name: String = "IncrementActive"
//    public let scope: CARuleScope = .active
//
//    public func evaluate(index: Voxels.VoxelIndex, readVoxels: Voxels.VoxelArray<VoxelType>, newVoxel: inout VoxelType, deltaTime _: Duration) -> CARuleResult {
//        // all actives stay active
//        newVoxel = (readVoxels[index] ?? 0) + 1
//        return .indexUpdated
//    }
// }
