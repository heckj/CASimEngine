/// A type that represents the result of processing a simulation rule.
///
/// When processing your rule, set ``updatedVoxel`` to `true` if the values were changed, `false` otherwise.
public struct CARuleResult: Sendable {
    /// A Boolean value that indicates wether the rule updated the voxel values.
    public let updatedVoxel: Bool
    /// An optional diagnostic that contains messages from the rule processing.
    public let diagnostic: CADiagnostic?

    /// Create a new result for a simulation rule.
    /// - Parameters:
    ///   - updated: `true` for updated voxel data, or `nil` if unchanged.
    ///   - diagnostic: An optional diagnostic detail snapshot.
    public init(_ updated: Bool, diagnostic: CADiagnostic? = nil) {
        updatedVoxel = updated
        self.diagnostic = diagnostic
    }

    /// A default result that indicates the rule updated the voxel.
    public static let indexUpdated: CARuleResult = .init(true)
    /// A default result that indicates the rule did not update the voxel.
    public static let noUpdate: CARuleResult = .init(false)
}
