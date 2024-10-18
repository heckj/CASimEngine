public import Voxels

/// A type that represents the result of processing a simulation rule.
///
/// The index location of the voxel your rule is processing is ``index``.
/// When processing a voxel with your rule, provide a value for ``updatedVoxel`` if the values were changed.
/// If the rule doesn't update the voxel, leave it `nil`.
///
/// If you want to send diagnostic messages for this rule and index location, append the messages to ``messages``.
public struct CAResult<T: Sendable>: Sendable {
    /// The index of the voxel.
    public let index: VoxelIndex
    /// The updated voxel value, if the value was changed.
    ///
    /// If your rules updates the values in the voxel, return the updated voxel.
    /// If your rules don't change the data within a voxel, return `nil`.
    public var updatedVoxel: T?
    /// Diagnostic messages from processing the rule.
    ///
    /// Add diagnostic messages for debugging or testing. These messages are included
    /// in instances of ``CADiagnostic`` streamed at ``CASimEngine/CASimEngine/diagnosticStream``.
    public var messages: [String]

    /// Create a new result for a simulation rule.
    /// - Parameters:
    ///   - index: The index location processed.
    ///   - updatedVoxel: The updated voxel data, or `nil` if unchanged
    ///   - messages: Diagnostic messages from processing the rule.
    public init(index: VoxelIndex, updatedVoxel: T? = nil, messages: [String] = []) {
        self.index = index
        self.updatedVoxel = updatedVoxel
        self.messages = messages
    }
}
