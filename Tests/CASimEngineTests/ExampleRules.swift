internal import CASimEngine
internal import Voxels

// MARK: example steps

struct SwapFluidMass: SwapStep {
    typealias StorageType = FluidSimStorage
    func perform(storage0: inout StorageType, storage1: inout StorageType) {
        // need access to storage0 and storage1
        swap(&storage0.fluidMass, &storage1.fluidMass)
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
