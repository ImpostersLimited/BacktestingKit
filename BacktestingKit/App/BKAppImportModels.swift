import Foundation

/// App-facing inspection result for pasted inline CSV workflows.
public struct BKAppCSVInspectionReport: Codable, Equatable, Sendable {
    /// Ticker symbol associated with this value.
    public var symbol: String
    /// Column mapping associated with this value.
    public var columnMapping: BKCSVColumnMapping?
    /// Preflight validation output associated with this value.
    public var preflight: BKToolPreflightReport
    /// Number of issues represented by this value.
    public var issueCount: Int
    /// Number of warnings represented by this value.
    public var warningCount: Int
    /// Number of errors represented by this value.
    public var errorCount: Int
    /// Whether this value is ready for the next workflow step.
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
    /// Machine-readable code associated with this value.
    public var code: String
    /// Human-readable message associated with this value.
    public var message: String
    /// Severity associated with this value.
    public var severity: BKValidationSeverity
    /// Additional metadata associated with this value.
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
    /// Column mapping associated with this value.
    public var columnMapping: BKCSVColumnMapping?
    /// Date format string used while parsing or formatting input.
    public var dateFormat: String?
    /// Whether the input should be reversed into chronological order.
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
    /// Column mapping associated with this value.
    public var columnMapping: BKCSVColumnMapping?
    /// Date format string used while parsing or formatting input.
    public var dateFormat: String
    /// Whether the input should be reversed into chronological order.
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
    /// Ticker symbol associated with this value.
    public var symbol: String
    /// Inspection result associated with this value.
    public var inspection: BKAppCSVInspectionReport
    /// Inferred settings associated with this value.
    public var inferredSettings: BKAppCSVInferredSettings
    /// Effective settings associated with this value.
    public var effectiveSettings: BKAppCSVEffectiveSettings
    /// Issues associated with this value.
    public var issues: [BKAppCSVInferenceIssue]
    /// Whether all import settings were inferred without ambiguity.
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
    /// Date associated with this value.
    public var date: Date
    /// Open price for the bar.
    public var open: Double
    /// High price for the bar.
    public var high: Double
    /// Low price for the bar.
    public var low: Double
    /// Close price for the bar.
    public var close: Double
    /// Adjusted close price for the bar when available.
    public var adjustedClose: Double?
    /// Trading volume for the bar.
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
    /// Ticker symbol associated with this value.
    public var symbol: String
    /// Date format string used while parsing or formatting input.
    public var dateFormat: String
    /// Whether the input should be reversed into chronological order.
    public var reverse: Bool
    /// Row limit associated with this value.
    public var rowLimit: Int
    /// Inspection result associated with this value.
    public var inspection: BKAppCSVInspectionReport
    /// Number of rows represented by this value.
    public var rowCount: Int
    /// Start date represented by this value.
    public var startDate: Date?
    /// End date represented by this value.
    public var endDate: Date?
    /// Rows associated with this value.
    public var rows: [BKAppCSVPreviewRow]
    /// Parse error associated with this value.
    public var parseError: String?
    /// Whether the operation completed successfully.
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
    /// Number of rows represented by this value.
    public var rowCount: Int
    /// Start date represented by this value.
    public var startDate: Date?
    /// End date represented by this value.
    public var endDate: Date?
    /// Effective settings associated with this value.
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
    /// Inferred settings and issues associated with this value.
    public var inference: BKAppCSVInferenceReport
    /// Preview output associated with this value.
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
    /// Ticker symbol associated with this value.
    public var symbol: String
    /// Inspection result associated with this value.
    public var inspection: BKAppCSVInspectionReport
    /// Parse validation associated with this value.
    public var parseValidation: BKValidationReport
    /// Parse error associated with this value.
    public var parseError: String?
    /// Whether the operation completed successfully.
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
    /// Inferred settings and issues associated with this value.
    public var inference: BKAppCSVInferenceReport
    /// Validation output associated with this value.
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
    /// Ticker symbol associated with this value.
    public var symbol: String
    /// Validation output associated with this value.
    public var validation: BKAppCSVValidationReport
    /// Bars associated with this value.
    public var bars: [BKBar]
    /// Candles associated with this value.
    public var candles: [Candlestick]
    /// Number of rows represented by this value.
    public var rowCount: Int
    /// Start date represented by this value.
    public var startDate: Date?
    /// End date represented by this value.
    public var endDate: Date?
    /// Parse error associated with this value.
    public var parseError: String?
    /// Whether the operation completed successfully.
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
    /// Number of rows represented by this value.
    public var rowCount: Int
    /// Start date represented by this value.
    public var startDate: Date?
    /// End date represented by this value.
    public var endDate: Date?
    /// Ordering normalized associated with this value.
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
    /// Inferred settings and issues associated with this value.
    public var inference: BKAppCSVInferenceReport
    /// Normalization output associated with this value.
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
    /// Current processing stage associated with this value.
    public var stage: BKAppCSVImportDiagnosticStage
    /// Outcome recorded for the associated stage.
    public var outcome: BKAppCSVImportStageOutcome
    /// Human-readable message associated with this value.
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
    /// Row index associated with this value.
    public var rowIndex: Int
    /// Raw row associated with this value.
    public var rawRow: String
    /// Human-readable message associated with this value.
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
    /// Ticker symbol associated with this value.
    public var symbol: String
    /// Inspection result associated with this value.
    public var inspection: BKAppCSVInspectionReport
    /// Inferred settings and issues associated with this value.
    public var inference: BKAppCSVInferenceReport
    /// Stage decisions associated with this value.
    public var stageDecisions: [BKAppCSVImportStageDecision]
    /// Failure stage associated with this value.
    public var failureStage: BKAppCSVImportFailureStage?
    /// Row failures associated with this value.
    public var rowFailures: [BKAppCSVRowFailureExample]
    /// Preview summary associated with this value.
    public var previewSummary: BKAppCSVPreviewSummary?
    /// Normalization summary associated with this value.
    public var normalizationSummary: BKAppCSVNormalizationSummary?
    /// Whether the import can proceed without blocking issues.
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
    /// Ticker symbol associated with this value.
    public var symbol: String
    /// Preset associated with this value.
    public var preset: BKPresetCatalog
    /// Validation output associated with this value.
    public var validation: BKAppCSVValidationReport
    /// Normalization output associated with this value.
    public var normalization: BKAppCSVNormalizedReport?
    /// Run associated with this value.
    public var run: BKPreflightedRunSummary?
    /// High-level summary associated with this value.
    public var summary: BKRunSummary?
    /// Human-readable failure description when execution does not succeed.
    public var failureDescription: String?
    /// Whether the operation completed successfully.
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
    /// Inferred settings and issues associated with this value.
    public var inference: BKAppCSVInferenceReport
    /// Run associated with this value.
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
    /// Column mapping associated with this value.
    public var columnMapping: BKCSVColumnMapping?
    /// Date format string used while parsing or formatting input.
    public var dateFormat: String
    /// Whether the input should be reversed into chronological order.
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
    /// Confirmed settings associated with this value.
    public var confirmedSettings: BKAppCSVConfirmedImportSettings
    /// Run associated with this value.
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
    /// Run associated with this value.
    public var run: BKAppCSVImportRunReport
    /// Markdown export generated for this value.
    public var markdown: String?
    /// Export failure associated with this value when generation does not succeed.
    public var exportError: BKExportError?
    /// Whether the operation completed successfully.
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
    /// Inferred settings and issues associated with this value.
    public var inference: BKAppCSVInferenceReport
    /// Run associated with this value.
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
    /// Severity associated with this value.
    public var severity: BKValidationSeverity
    /// Machine-readable code associated with this value.
    public var code: String
    /// Human-readable message associated with this value.
    public var message: String
    /// Source associated with this value.
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
    /// Title associated with this value.
    public var title: String
    /// Items associated with this value.
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
    /// Ticker symbol associated with this value.
    public var symbol: String
    /// Inspection result associated with this value.
    public var inspection: BKAppCSVInspectionReport
    /// Inferred settings and issues associated with this value.
    public var inference: BKAppCSVInferenceReport
    /// Preview output associated with this value.
    public var preview: BKAppCSVAutoPreviewReport?
    /// Validation output associated with this value.
    public var validation: BKAppCSVAutoValidationReport?
    /// Normalization output associated with this value.
    public var normalization: BKAppCSVAutoNormalizedReport?
    /// Issues associated with this value.
    public var issues: [BKAppCSVImportIssueSection]
    /// Current status associated with this value.
    public var status: BKAppCSVImportScreenStatus
    /// Whether the workflow can continue without additional user input.
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
