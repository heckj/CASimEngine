/// A type that represents the result of processing a simulation rule.
///
/// The index location of the voxel your rule is processing is ``index``.
/// When processing a voxel with your rule, provide a value for ``updatedVoxel`` if the values were changed.
/// If the rule doesn't update the voxel, leave it `nil`.
///
/// If you want to send diagnostic messages for this rule and index location, append the messages to ``messages``.
public struct CADirectRuleResult: Sendable {
    public let updatedVoxel: Bool
    public let diagnostic: CADiagnostic?

    /// Create a new result for a simulation rule.
    /// - Parameters:
    ///   - index: The index location processed.
    ///   - updatedVoxel: The updated voxel data, or `nil` if unchanged
    ///   - messages: Diagnostic messages from processing the rule.
    public init(_ updateed: Bool, diagnostic: CADiagnostic? = nil) {
        updatedVoxel = updateed
        self.diagnostic = diagnostic
    }

    public static let indexUpdated: CADirectRuleResult = .init(true)
    public static let noUpdate: CADirectRuleResult = .init(false)
}
