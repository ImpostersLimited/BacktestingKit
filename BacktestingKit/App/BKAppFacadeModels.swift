import Foundation

/// Result of running a preset-backed inline CSV workflow and exporting the outcome as Markdown.
public struct BKAppPresetMarkdownReport {
    /// Run associated with this value.
    public var run: BKPreflightedRunSummary
    /// Markdown export generated for this value.
    public var markdown: String?
    /// Export failure associated with this value when generation does not succeed.
    public var exportError: BKExportError?
    /// Whether the operation completed successfully.
    public var isSuccessful: Bool

    /// Creates a new instance.
    public init(
        run: BKPreflightedRunSummary,
        markdown: String? = nil,
        exportError: BKExportError? = nil,
        isSuccessful: Bool
    ) {
        self.run = run
        self.markdown = markdown
        self.exportError = exportError
        self.isSuccessful = isSuccessful
    }
}

/// Result of running a deterministic scenario and exporting the outcome as a portable bundle.
public struct BKAppScenarioBundleReport {
    /// Configuration associated with this value.
    public var config: BKScenarioConfig
    /// High-level summary associated with this value.
    public var summary: BKRunSummary
    /// Export bundle associated with this value.
    public var exportBundle: BKRunExportBundle?
    /// Export failure associated with this value when generation does not succeed.
    public var exportError: BKExportError?
    /// Whether the operation completed successfully.
    public var isSuccessful: Bool

    /// Creates a new instance.
    public init(
        config: BKScenarioConfig,
        summary: BKRunSummary,
        exportBundle: BKRunExportBundle? = nil,
        exportError: BKExportError? = nil,
        isSuccessful: Bool
    ) {
        self.config = config
        self.summary = summary
        self.exportBundle = exportBundle
        self.exportError = exportError
        self.isSuccessful = isSuccessful
    }
}
