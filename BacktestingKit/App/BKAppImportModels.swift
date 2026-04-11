import Foundation

/// App-facing inspection result for pasted inline CSV workflows.
public struct BKAppCSVInspectionReport: Codable, Equatable, Sendable {
    public var symbol: String
    public var columnMapping: BKCSVColumnMapping?
    public var preflight: BKToolPreflightReport
    public var issueCount: Int
    public var warningCount: Int
    public var errorCount: Int
    public var isReady: Bool

    /// Creates a new instance.
    public init(
        symbol: String,
        columnMapping: BKCSVColumnMapping? = nil,
        preflight: BKToolPreflightReport,
        issueCount: Int,
        warningCount: Int,
        errorCount: Int,
        isReady: Bool
    ) {
        self.symbol = symbol
        self.columnMapping = columnMapping
        self.preflight = preflight
        self.issueCount = issueCount
        self.warningCount = warningCount
        self.errorCount = errorCount
        self.isReady = isReady
    }
}

/// A single CSV inference finding for app-facing import flows.
public struct BKAppCSVInferenceIssue: Codable, Equatable, Sendable {
    public var code: String
    public var message: String
    public var severity: BKValidationSeverity
    public var metadata: [String: String]

    /// Creates a new instance.
    public init(
        code: String,
        message: String,
        severity: BKValidationSeverity,
        metadata: [String: String] = [:]
    ) {
        self.code = code
        self.message = message
        self.severity = severity
        self.metadata = metadata
    }
}

/// Inferred CSV import settings before default fallback is applied.
public struct BKAppCSVInferredSettings: Codable, Equatable, Sendable {
    public var columnMapping: BKCSVColumnMapping?
    public var dateFormat: String?
    public var reverse: Bool?

    /// Creates a new instance.
    public init(
        columnMapping: BKCSVColumnMapping? = nil,
        dateFormat: String? = nil,
        reverse: Bool? = nil
    ) {
        self.columnMapping = columnMapping
        self.dateFormat = dateFormat
        self.reverse = reverse
    }
}

/// Effective CSV import settings after inference fallback/default resolution.
public struct BKAppCSVEffectiveSettings: Codable, Equatable, Sendable {
    public var columnMapping: BKCSVColumnMapping?
    public var dateFormat: String
    public var reverse: Bool

    /// Creates a new instance.
    public init(
        columnMapping: BKCSVColumnMapping? = nil,
        dateFormat: String,
        reverse: Bool
    ) {
        self.columnMapping = columnMapping
        self.dateFormat = dateFormat
        self.reverse = reverse
    }
}

/// Safe CSV import inference result for app-facing CSV workflows.
public struct BKAppCSVInferenceReport: Codable, Equatable, Sendable {
    public var symbol: String
    public var inspection: BKAppCSVInspectionReport
    public var inferredSettings: BKAppCSVInferredSettings
    public var effectiveSettings: BKAppCSVEffectiveSettings
    public var issues: [BKAppCSVInferenceIssue]
    public var isFullyInferred: Bool

    /// Creates a new instance.
    public init(
        symbol: String,
        inspection: BKAppCSVInspectionReport,
        inferredSettings: BKAppCSVInferredSettings,
        effectiveSettings: BKAppCSVEffectiveSettings,
        issues: [BKAppCSVInferenceIssue],
        isFullyInferred: Bool
    ) {
        self.symbol = symbol
        self.inspection = inspection
        self.inferredSettings = inferredSettings
        self.effectiveSettings = effectiveSettings
        self.issues = issues
        self.isFullyInferred = isFullyInferred
    }
}

/// Lightweight preview row for app-side CSV inspection UIs.
public struct BKAppCSVPreviewRow: Codable, Equatable, Sendable {
    public var date: Date
    public var open: Double
    public var high: Double
    public var low: Double
    public var close: Double
    public var adjustedClose: Double?
    public var volume: Double

    /// Creates a new instance.
    public init(
        date: Date,
        open: Double,
        high: Double,
        low: Double,
        close: Double,
        adjustedClose: Double? = nil,
        volume: Double
    ) {
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.adjustedClose = adjustedClose
        self.volume = volume
    }
}

/// Preview-oriented report for CSV parsing and bounded row inspection.
public struct BKAppCSVPreviewReport: Codable, Equatable, Sendable {
    public var symbol: String
    public var dateFormat: String
    public var reverse: Bool
    public var rowLimit: Int
    public var inspection: BKAppCSVInspectionReport
    public var rowCount: Int
    public var startDate: Date?
    public var endDate: Date?
    public var rows: [BKAppCSVPreviewRow]
    public var parseError: String?
    public var isSuccessful: Bool

    /// Creates a new instance.
    public init(
        symbol: String,
        dateFormat: String,
        reverse: Bool,
        rowLimit: Int,
        inspection: BKAppCSVInspectionReport,
        rowCount: Int = 0,
        startDate: Date? = nil,
        endDate: Date? = nil,
        rows: [BKAppCSVPreviewRow] = [],
        parseError: String? = nil,
        isSuccessful: Bool
    ) {
        self.symbol = symbol
        self.dateFormat = dateFormat
        self.reverse = reverse
        self.rowLimit = rowLimit
        self.inspection = inspection
        self.rowCount = rowCount
        self.startDate = startDate
        self.endDate = endDate
        self.rows = rows
        self.parseError = parseError
        self.isSuccessful = isSuccessful
    }
}

/// Compact preview summary for app-facing CSV diagnostics.
public struct BKAppCSVPreviewSummary: Codable, Equatable, Sendable {
    public var rowCount: Int
    public var startDate: Date?
    public var endDate: Date?
    public var effectiveSettings: BKAppCSVEffectiveSettings

    /// Creates a new instance.
    public init(
        rowCount: Int,
        startDate: Date? = nil,
        endDate: Date? = nil,
        effectiveSettings: BKAppCSVEffectiveSettings
    ) {
        self.rowCount = rowCount
        self.startDate = startDate
        self.endDate = endDate
        self.effectiveSettings = effectiveSettings
    }
}

/// Auto-inference wrapper around `BKAppCSVPreviewReport`.
public struct BKAppCSVAutoPreviewReport: Codable, Equatable, Sendable {
    public var inference: BKAppCSVInferenceReport
    public var preview: BKAppCSVPreviewReport

    /// Creates a new instance.
    public init(
        inference: BKAppCSVInferenceReport,
        preview: BKAppCSVPreviewReport
    ) {
        self.inference = inference
        self.preview = preview
    }
}

/// Validation bundle that combines structural CSV preflight with parse-stage validation.
public struct BKAppCSVValidationReport: Codable, Equatable, Sendable {
    public var symbol: String
    public var inspection: BKAppCSVInspectionReport
    public var parseValidation: BKValidationReport
    public var parseError: String?
    public var isSuccessful: Bool

    /// Creates a new instance.
    public init(
        symbol: String,
        inspection: BKAppCSVInspectionReport,
        parseValidation: BKValidationReport,
        parseError: String? = nil,
        isSuccessful: Bool
    ) {
        self.symbol = symbol
        self.inspection = inspection
        self.parseValidation = parseValidation
        self.parseError = parseError
        self.isSuccessful = isSuccessful
    }
}

/// Auto-inference wrapper around `BKAppCSVValidationReport`.
public struct BKAppCSVAutoValidationReport: Codable, Equatable, Sendable {
    public var inference: BKAppCSVInferenceReport
    public var validation: BKAppCSVValidationReport

    /// Creates a new instance.
    public init(
        inference: BKAppCSVInferenceReport,
        validation: BKAppCSVValidationReport
    ) {
        self.inference = inference
        self.validation = validation
    }
}

/// Normalized parse output for app-side CSV import flows.
public struct BKAppCSVNormalizedReport: Codable, Equatable {
    public var symbol: String
    public var validation: BKAppCSVValidationReport
    public var bars: [BKBar]
    public var candles: [Candlestick]
    public var rowCount: Int
    public var startDate: Date?
    public var endDate: Date?
    public var parseError: String?
    public var isSuccessful: Bool

    /// Creates a new instance.
    public init(
        symbol: String,
        validation: BKAppCSVValidationReport,
        bars: [BKBar] = [],
        candles: [Candlestick] = [],
        rowCount: Int = 0,
        startDate: Date? = nil,
        endDate: Date? = nil,
        parseError: String? = nil,
        isSuccessful: Bool
    ) {
        self.symbol = symbol
        self.validation = validation
        self.bars = bars
        self.candles = candles
        self.rowCount = rowCount
        self.startDate = startDate
        self.endDate = endDate
        self.parseError = parseError
        self.isSuccessful = isSuccessful
    }
}

/// Compact normalization summary for app-facing CSV diagnostics.
public struct BKAppCSVNormalizationSummary: Codable, Equatable, Sendable {
    public var rowCount: Int
    public var startDate: Date?
    public var endDate: Date?
    public var orderingNormalized: Bool

    /// Creates a new instance.
    public init(
        rowCount: Int,
        startDate: Date? = nil,
        endDate: Date? = nil,
        orderingNormalized: Bool
    ) {
        self.rowCount = rowCount
        self.startDate = startDate
        self.endDate = endDate
        self.orderingNormalized = orderingNormalized
    }
}

/// Auto-inference wrapper around `BKAppCSVNormalizedReport`.
public struct BKAppCSVAutoNormalizedReport: Equatable {
    public var inference: BKAppCSVInferenceReport
    public var normalization: BKAppCSVNormalizedReport

    /// Creates a new instance.
    public init(
        inference: BKAppCSVInferenceReport,
        normalization: BKAppCSVNormalizedReport
    ) {
        self.inference = inference
        self.normalization = normalization
    }
}

/// The diagnostic stage used by the app-facing CSV import report.
public enum BKAppCSVImportDiagnosticStage: String, Codable, Equatable, Sendable {
    case inspection
    case inference
    case preview
    case validation
    case normalization
}

/// The outcome of a single diagnostics stage.
public enum BKAppCSVImportStageOutcome: String, Codable, Equatable, Sendable {
    case success
    case warning
    case failed
    case skipped
}

/// The first stage that failed decisively during CSV import diagnostics.
public enum BKAppCSVImportFailureStage: String, Codable, Equatable, Sendable {
    case inspection
    case inference
    case preview
    case validation
    case normalization
}

/// A single stage decision captured by the CSV import diagnostics helper.
public struct BKAppCSVImportStageDecision: Codable, Equatable, Sendable {
    public var stage: BKAppCSVImportDiagnosticStage
    public var outcome: BKAppCSVImportStageOutcome
    public var message: String

    /// Creates a new instance.
    public init(
        stage: BKAppCSVImportDiagnosticStage,
        outcome: BKAppCSVImportStageOutcome,
        message: String
    ) {
        self.stage = stage
        self.outcome = outcome
        self.message = message
    }
}

/// A bounded concrete row failure example emitted by the CSV import diagnostics helper.
public struct BKAppCSVRowFailureExample: Codable, Equatable, Sendable {
    public var rowIndex: Int
    public var rawRow: String
    public var message: String

    /// Creates a new instance.
    public init(
        rowIndex: Int,
        rawRow: String,
        message: String
    ) {
        self.rowIndex = rowIndex
        self.rawRow = rawRow
        self.message = message
    }
}

/// Developer-facing diagnostics report for the app-side CSV import pipeline.
public struct BKAppCSVImportDiagnosticsReport: Codable, Equatable, Sendable {
    public var symbol: String
    public var inspection: BKAppCSVInspectionReport
    public var inference: BKAppCSVInferenceReport
    public var stageDecisions: [BKAppCSVImportStageDecision]
    public var failureStage: BKAppCSVImportFailureStage?
    public var rowFailures: [BKAppCSVRowFailureExample]
    public var previewSummary: BKAppCSVPreviewSummary?
    public var normalizationSummary: BKAppCSVNormalizationSummary?
    public var isImportViable: Bool

    /// Creates a new instance.
    public init(
        symbol: String,
        inspection: BKAppCSVInspectionReport,
        inference: BKAppCSVInferenceReport,
        stageDecisions: [BKAppCSVImportStageDecision],
        failureStage: BKAppCSVImportFailureStage? = nil,
        rowFailures: [BKAppCSVRowFailureExample] = [],
        previewSummary: BKAppCSVPreviewSummary? = nil,
        normalizationSummary: BKAppCSVNormalizationSummary? = nil,
        isImportViable: Bool
    ) {
        self.symbol = symbol
        self.inspection = inspection
        self.inference = inference
        self.stageDecisions = stageDecisions
        self.failureStage = failureStage
        self.rowFailures = rowFailures
        self.previewSummary = previewSummary
        self.normalizationSummary = normalizationSummary
        self.isImportViable = isImportViable
    }
}

/// Aggregated app-facing output for validate + normalize + preset execution workflows.
public struct BKAppCSVImportRunReport {
    public var symbol: String
    public var preset: BKPresetCatalog
    public var validation: BKAppCSVValidationReport
    public var normalization: BKAppCSVNormalizedReport?
    public var run: BKPreflightedRunSummary?
    public var summary: BKRunSummary?
    public var failureDescription: String?
    public var isSuccessful: Bool

    /// Creates a new instance.
    public init(
        symbol: String,
        preset: BKPresetCatalog,
        validation: BKAppCSVValidationReport,
        normalization: BKAppCSVNormalizedReport? = nil,
        run: BKPreflightedRunSummary? = nil,
        summary: BKRunSummary? = nil,
        failureDescription: String? = nil,
        isSuccessful: Bool
    ) {
        self.symbol = symbol
        self.preset = preset
        self.validation = validation
        self.normalization = normalization
        self.run = run
        self.summary = summary
        self.failureDescription = failureDescription
        self.isSuccessful = isSuccessful
    }
}

/// Auto-inference wrapper around `BKAppCSVImportRunReport`.
public struct BKAppCSVAutoRunReport {
    public var inference: BKAppCSVInferenceReport
    public var run: BKAppCSVImportRunReport

    /// Creates a new instance.
    public init(
        inference: BKAppCSVInferenceReport,
        run: BKAppCSVImportRunReport
    ) {
        self.inference = inference
        self.run = run
    }
}

/// Explicit CSV import settings confirmed by the app after review or user override.
public struct BKAppCSVConfirmedImportSettings: Codable, Equatable, Sendable {
    public var columnMapping: BKCSVColumnMapping?
    public var dateFormat: String
    public var reverse: Bool

    /// Creates a new instance.
    public init(
        columnMapping: BKCSVColumnMapping? = nil,
        dateFormat: String,
        reverse: Bool
    ) {
        self.columnMapping = columnMapping
        self.dateFormat = dateFormat
        self.reverse = reverse
    }
}

/// Result of executing a confirmed CSV import after an app-side review step.
public struct BKAppCSVConfirmedRunReport {
    public var confirmedSettings: BKAppCSVConfirmedImportSettings
    public var run: BKAppCSVImportRunReport

    /// Creates a new instance.
    public init(
        confirmedSettings: BKAppCSVConfirmedImportSettings,
        run: BKAppCSVImportRunReport
    ) {
        self.confirmedSettings = confirmedSettings
        self.run = run
    }
}

/// Result of running an app-facing CSV import workflow and exporting the outcome as Markdown.
public struct BKAppCSVImportMarkdownReport {
    public var run: BKAppCSVImportRunReport
    public var markdown: String?
    public var exportError: BKExportError?
    public var isSuccessful: Bool

    /// Creates a new instance.
    public init(
        run: BKAppCSVImportRunReport,
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

/// Auto-inference wrapper around `BKAppCSVImportMarkdownReport`.
public struct BKAppCSVAutoMarkdownReport {
    public var inference: BKAppCSVInferenceReport
    public var run: BKAppCSVImportMarkdownReport

    /// Creates a new instance.
    public init(
        inference: BKAppCSVInferenceReport,
        run: BKAppCSVImportMarkdownReport
    ) {
        self.inference = inference
        self.run = run
    }
}

/// High-level status for an app-facing CSV import review screen.
public enum BKAppCSVImportScreenStatus: String, Codable, Equatable, Sendable {
    case ready
    case needsReview
    case invalid
}

/// The source section for a grouped import-review issue.
public enum BKAppCSVImportIssueSource: String, Codable, Equatable, Sendable {
    case inspection
    case inference
    case validation
}

/// A single user-displayable issue row for import-review UIs.
public struct BKAppCSVImportIssueItem: Codable, Equatable, Sendable {
    public var severity: BKValidationSeverity
    public var code: String
    public var message: String
    public var source: BKAppCSVImportIssueSource

    /// Creates a new instance.
    public init(
        severity: BKValidationSeverity,
        code: String,
        message: String,
        source: BKAppCSVImportIssueSource
    ) {
        self.severity = severity
        self.code = code
        self.message = message
        self.source = source
    }
}

/// A grouped section of issues for app-facing import-review UIs.
public struct BKAppCSVImportIssueSection: Codable, Equatable, Sendable {
    public var title: String
    public var items: [BKAppCSVImportIssueItem]

    /// Creates a new instance.
    public init(
        title: String,
        items: [BKAppCSVImportIssueItem]
    ) {
        self.title = title
        self.items = items
    }
}

/// Aggregated screen-state payload for app-facing CSV import review flows.
public struct BKAppCSVImportScreenState: Equatable {
    public var symbol: String
    public var inspection: BKAppCSVInspectionReport
    public var inference: BKAppCSVInferenceReport
    public var preview: BKAppCSVAutoPreviewReport?
    public var validation: BKAppCSVAutoValidationReport?
    public var normalization: BKAppCSVAutoNormalizedReport?
    public var issues: [BKAppCSVImportIssueSection]
    public var status: BKAppCSVImportScreenStatus
    public var isReadyToContinue: Bool

    /// Creates a new instance.
    public init(
        symbol: String,
        inspection: BKAppCSVInspectionReport,
        inference: BKAppCSVInferenceReport,
        preview: BKAppCSVAutoPreviewReport? = nil,
        validation: BKAppCSVAutoValidationReport? = nil,
        normalization: BKAppCSVAutoNormalizedReport? = nil,
        issues: [BKAppCSVImportIssueSection],
        status: BKAppCSVImportScreenStatus,
        isReadyToContinue: Bool
    ) {
        self.symbol = symbol
        self.inspection = inspection
        self.inference = inference
        self.preview = preview
        self.validation = validation
        self.normalization = normalization
        self.issues = issues
        self.status = status
        self.isReadyToContinue = isReadyToContinue
    }
}
