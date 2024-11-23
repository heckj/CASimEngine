/// A cellular automata simulation rule.
public enum CASimulationRule<StorageType: CASimulationStorage> {
    /// A rule that swaps two storage values.
    case swap(name: String, any SwapStep<StorageType>)
    /// A rule that evaluates cells.
    case eval(name: String, scope: CARuleScope, any EvaluateStep<StorageType>)
}

/// A type that provides the logic to swap storage values.
public protocol SwapStep<StorageType> {
    /// The type that conforms to StorageProtocol that this rule applies to.
    associatedtype StorageType: CASimulationStorage
    /// The function that the simulation engine calls to swap some properties within the engine's storage.
    /// - Parameters:
    ///   - storage0: The first storage instance.
    ///   - storage1: The second storage instance.
    func perform(storage0: inout StorageType, storage1: inout StorageType)
}

/// A type that provides the logic to evaluate cells.
public protocol EvaluateStep<StorageType> {
    /// The type that conforms to StorageProtocol that this rule applies to.
    associatedtype StorageType: CASimulationStorage
    /// The function that the simulation engine calls to process a cell.
    /// - Parameters:
    ///   - linearIndex: The linear index of the cell to process.
    ///   - storage0: The first storage engine.
    ///   - storage1: The second storage engine.
    /// - Returns: a simulation result indicator with optional diagnostic messages.
    func evaluate(linearIndex: Int, storage0: StorageType, storage1: inout StorageType) -> CARuleResult
}
