import CASimEngine
import Voxels

struct SingleIntStorage: StorageProtocol {
    let bounds: VoxelBounds
    
    var floatValue: Array<Int> = []

    init(_ voxels: VoxelArray<Int>) {
        bounds = voxels.bounds
        for i in 0..<bounds.size {
            //let voxelIndex = bounds._unchecked_delinearize(i)
            floatValue.append(voxels[i])
        }
                
    }
    
    func changes() -> [VoxelUpdate<T>] {
        return []
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
    func evaluate(linearIndex: Int, storage0: StorageType, storage1: inout StorageType) -> CARuleResult {
        storage1.floatValue[linearIndex] = storage0.floatValue[linearIndex] + 1
        return .indexUpdated
    }
}
