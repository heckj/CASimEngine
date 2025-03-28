internal import CASimEngine
internal import Voxels

struct SingleFloatStorage: CASimulationStorage {
    public typealias T = Float
    let bounds: VoxelBounds
    public let uninitializedDefault: Float = 0.0

    var floatValue: [T] = []

    @inlinable
    init(_ voxels: VoxelArray<T>) {
        bounds = voxels.bounds
        for i in 0 ..< bounds.size {
            // let voxelIndex = bounds._unchecked_delinearize(i)
            floatValue.append(voxels[i])
        }
    }

    @inlinable
    public func voxelAt(_ index: Int) -> T {
        floatValue[index]
    }

    @inlinable
    public var current: VoxelArray<T> {
        var newArray = VoxelArray<T>(bounds: bounds, initialValue: 0)
        for i in 0 ..< bounds.size {
            newArray[i] = floatValue[i]
        }
        return newArray
    }
}

struct IncrementSingleFloat: EvaluateStep {
    typealias StorageType = SingleFloatStorage
    func evaluate(cell: CAIndex, deltaTime _: Duration, storage0: StorageType, storage1: inout StorageType) -> CARuleResult {
        // need read access to storage0 and write access to storage1
        storage1.floatValue[cell.index] = storage0.floatValue[cell.index] + Float(1)

        // computing the voxelIndex from the linear index
        // let _ = storage0.bounds._unchecked_delinearize(linearIndex)
        return .indexUpdated
    }
}

struct SwapSingleFloat: SwapStep {
    typealias StorageType = SingleFloatStorage
    func perform(storage0: inout StorageType, storage1: inout StorageType) {
        swap(&storage0, &storage1)
    }
}
