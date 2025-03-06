import CASimEngine
import Voxels

struct SingleIntStorage: CASimulationStorage {
    var uninitializedDefault: Int
    
    func voxelAt(_ index: Int) -> Int {
        floatValue[index]
    }
    
    let bounds: VoxelBounds

    var floatValue: [Int] = []

    init(_ voxels: VoxelArray<Int>) {
        uninitializedDefault = 0
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

struct SwapInt: SwapStep {
    typealias StorageType = SingleIntStorage
    func perform(storage0: inout SingleIntStorage, storage1: inout SingleIntStorage) {
        swap(&storage0.floatValue, &storage1.floatValue)
    }
}

struct IncrementSingleInt: EvaluateStep {
    typealias StorageType = SingleIntStorage
    func evaluate(cell: CAIndex, deltaTime: Duration, storage0: StorageType, storage1: inout StorageType) -> CARuleResult {
        storage1.floatValue[cell.index] = storage0.floatValue[cell.index] + 1
        return .indexUpdated
    }
}
