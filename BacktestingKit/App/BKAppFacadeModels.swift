import Foundation

/// Result of running a preset-backed inline CSV workflow and exporting the outcome as Markdown.
public struct BKAppPresetMarkdownReport {
    public var run: BKPreflightedRunSummary
    public var markdown: String?
    public var exportError: BKExportError?
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
    public var config: BKScenarioConfig
    public var summary: BKRunSummary
    public var exportBundle: BKRunExportBundle?
    public var exportError: BKExportError?
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
