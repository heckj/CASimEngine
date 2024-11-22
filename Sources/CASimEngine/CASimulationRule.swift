// public import Voxels
//
///// A type that processes voxels within a cellular automata simulation.
// public protocol CASimulationRule: Sendable {
//    associatedtype T
//    /// The name of the rule
//    var name: String { get }
//    /// The set of voxels to process.
//    var scope: CARuleScope { get }
//
//    /// The function that the simulation engine calls to process a voxel.
//    /// - Parameters:
//    ///   - index: The index of the voxel within the simulation.
//    ///   - readVoxels: The set of voxels that hold the current state.
//    ///   - newVoxel: The voxel to update.
//    ///   - deltaTime: The change in time in the simulation.
//    /// - Returns: A result that indicates if the evaluation changed a voxel, and optionally diagnostic messages from this rule.
//    func evaluate(index: VoxelIndex, readVoxels: Storage<T>, newVoxel: inout Storage<T>, deltaTime: Duration) -> CARuleResult
// }

public enum CASimulationRule<StorageType: StorageProtocol> {
    case swap(name: String, any SwapStep<StorageType>)
    case eval(name: String, scope: CARuleScope, any EvaluateStep<StorageType>)
}

public protocol SwapStep<StorageType> {
    associatedtype StorageType: StorageProtocol
    func perform(storage0: inout StorageType, storage1: inout StorageType)
}

public protocol EvaluateStep<StorageType> {
    associatedtype StorageType: StorageProtocol
    func evaluate(linearIndex: Int, storage0: StorageType, storage1: inout StorageType) -> CARuleResult
}

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

// struct IncrementVelYVoxel {
//    func evaluate(index: VoxelIndex, storage0: Storage, storage1: inout Storage) {
//        // need read access to storage0 and write access to storage1
//        let linearIndex = storage0.bounds._unchecked_linearize(index)
//        storage1.fluidVelY[linearIndex] = storage0.fluidVelY[linearIndex] + Float(1)
//    }
// }
