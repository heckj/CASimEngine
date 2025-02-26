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
    ///   - cell: The position of the cell to process and the linear index locations of its neighbors.
    ///   - deltaTime: The time step to use for the rule evaluation.
    ///   - storage0: The first storage container (to read from).
    ///   - storage1: The second storage container (to write to).
    /// - Returns: a simulation result indicator with optional diagnostic messages.
    func evaluate(cell: CAIndex, deltaTime: Duration, storage0: StorageType, storage1: inout StorageType) -> CARuleResult
}
