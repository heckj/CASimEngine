internal import CASimEngine
internal import Voxels

struct SingleIntStorage: CASimulationStorage {
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

struct SwapSingleInt: SwapStep {
    typealias StorageType = SingleIntStorage
    func perform(storage0: inout StorageType, storage1: inout StorageType) {
        swap(&storage0, &storage1)
    }
}
