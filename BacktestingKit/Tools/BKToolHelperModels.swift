import Foundation

/// Aggregated output from a helper-driven CSV preflight workflow.
public struct BKToolPreflightReport: Codable, Equatable, Sendable {
    /// Ticker symbol associated with this value.
    public var symbol: String?
    /// Number of rows represented by this value.
    public var rowCount: Int?
    /// Start date represented by this value.
    public var startDate: Date?
    /// End date represented by this value.
    public var endDate: Date?
    /// Validation output associated with this value.
    public var validation: BKValidationReport
    /// Diagnostics associated with this value.
    public var diagnostics: [BKDiagnosticEvent]
    /// Whether this value is ready for the next workflow step.
    public var isReady: Bool

    /// Creates a new instance.
    public init(
        symbol: String? = nil,
        rowCount: Int? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        validation: BKValidationReport,
        diagnostics: [BKDiagnosticEvent] = [],
        isReady: Bool
    ) {
        self.symbol = symbol
        self.rowCount = rowCount
        self.startDate = startDate
        self.endDate = endDate
        self.validation = validation
        self.diagnostics = diagnostics
        self.isReady = isReady
    }
}

/// Export-ready text payloads emitted by helper workflows.
public struct BKToolExportBundle: Codable, Equatable, Sendable {
    /// Preflight json associated with this value.
    public var preflightJSON: String
    /// Diagnostics json associated with this value.
    public var diagnosticsJSON: String?
    /// Trades CSV associated with this value.
    public var tradesCSV: String?

    /// Creates a new instance.
    public init(
        preflightJSON: String,
        diagnosticsJSON: String? = nil,
        tradesCSV: String? = nil
    ) {
        self.preflightJSON = preflightJSON
        self.diagnosticsJSON = diagnosticsJSON
        self.tradesCSV = tradesCSV
    }
}

/// Aggregated diagnostics snapshot suitable for smoke-test and export workflows.
public struct BKDiagnosticsSnapshotReport: Codable, Equatable, Sendable {
    /// Event count represented by this value.
    public var eventCount: Int
    /// First timestamp associated with this value.
    public var firstTimestamp: Date?
    /// Last timestamp associated with this value.
    public var lastTimestamp: Date?
    /// Stage counts associated with this value.
    public var stageCounts: [String: Int]
    /// Last failure event associated with this value.
    public var lastFailureEvent: BKDiagnosticEvent?

    /// Creates a new instance.
    public init(
        eventCount: Int,
        firstTimestamp: Date? = nil,
        lastTimestamp: Date? = nil,
        stageCounts: [String: Int] = [:],
        lastFailureEvent: BKDiagnosticEvent? = nil
    ) {
        self.eventCount = eventCount
        self.firstTimestamp = firstTimestamp
        self.lastTimestamp = lastTimestamp
        self.stageCounts = stageCounts
        self.lastFailureEvent = lastFailureEvent
    }
}

/// Export-ready payloads for completed runs and smoke-test artifacts.
public struct BKRunExportBundle: Codable, Equatable, Sendable {
    /// Summary json associated with this value.
    public var summaryJSON: String
    /// Diagnostics summary json associated with this value.
    public var diagnosticsSummaryJSON: String?
    /// Trades CSV associated with this value.
    public var tradesCSV: String?
    /// Scenario json associated with this value.
    public var scenarioJSON: String?

    /// Creates a new instance.
    public init(
        summaryJSON: String,
        diagnosticsSummaryJSON: String? = nil,
        tradesCSV: String? = nil,
        scenarioJSON: String? = nil
    ) {
        self.summaryJSON = summaryJSON
        self.diagnosticsSummaryJSON = diagnosticsSummaryJSON
        self.tradesCSV = tradesCSV
        self.scenarioJSON = scenarioJSON
    }
}

/// Metric-by-metric delta between two run summaries.
public struct BKRunMetricDiff: Codable, Equatable, Sendable {
    /// Baseline associated with this value.
    public var baseline: BKRunHeadlineMetrics
    /// Candidate associated with this value.
    public var candidate: BKRunHeadlineMetrics
    /// Trade count delta associated with this value.
    public var tradeCountDelta: Int
    /// Win rate delta associated with this value.
    public var winRateDelta: Double
    /// Total return delta represented by this value.
    public var totalReturnDelta: Double
    /// Annualized return delta associated with this value.
    public var annualizedReturnDelta: Double
    /// Maximum drawdown delta associated with this value.
    public var maxDrawdownDelta: Double
    /// Sharpe ratio delta associated with this value.
    public var sharpeRatioDelta: Double
    /// Profit factor delta associated with this value.
    public var profitFactorDelta: Double

    /// Creates a new instance.
    public init(
        baseline: BKRunHeadlineMetrics,
        candidate: BKRunHeadlineMetrics,
        tradeCountDelta: Int,
        winRateDelta: Double,
        totalReturnDelta: Double,
        annualizedReturnDelta: Double,
        maxDrawdownDelta: Double,
        sharpeRatioDelta: Double,
        profitFactorDelta: Double
    ) {
        self.baseline = baseline
        self.candidate = candidate
        self.tradeCountDelta = tradeCountDelta
        self.winRateDelta = winRateDelta
        self.totalReturnDelta = totalReturnDelta
        self.annualizedReturnDelta = annualizedReturnDelta
        self.maxDrawdownDelta = maxDrawdownDelta
        self.sharpeRatioDelta = sharpeRatioDelta
        self.profitFactorDelta = profitFactorDelta
    }
}

/// Structured summary diff for onboarding and regression review workflows.
public struct BKRunSummaryDiff: Codable, Equatable, Sendable {
    /// Baseline associated with this value.
    public var baseline: BKRunSummary
    /// Candidate associated with this value.
    public var candidate: BKRunSummary
    /// Symbol changed associated with this value.
    public var symbolChanged: Bool
    /// Bar count delta associated with this value.
    public var barCountDelta: Int
    /// Start date changed associated with this value.
    public var startDateChanged: Bool
    /// End date changed associated with this value.
    public var endDateChanged: Bool
    /// Headline metrics associated with this value.
    public var metrics: BKRunMetricDiff

    /// Creates a new instance.
    public init(
        baseline: BKRunSummary,
        candidate: BKRunSummary,
        symbolChanged: Bool,
        barCountDelta: Int,
        startDateChanged: Bool,
        endDateChanged: Bool,
        metrics: BKRunMetricDiff
    ) {
        self.baseline = baseline
        self.candidate = candidate
        self.symbolChanged = symbolChanged
        self.barCountDelta = barCountDelta
        self.startDateChanged = startDateChanged
        self.endDateChanged = endDateChanged
        self.metrics = metrics
    }
}

/// Comparison report that flags whether summary differences exceed a caller-supplied tolerance.
public struct BKRunComparisonReport: Codable, Equatable, Sendable {
    /// Diff associated with this value.
    public var diff: BKRunSummaryDiff
    /// Tolerance associated with this value.
    public var tolerance: Double
    /// Compared field count represented by this value.
    public var comparedFieldCount: Int
    /// Changed field count represented by this value.
    public var changedFieldCount: Int
    /// Materially different fields associated with this value.
    public var materiallyDifferentFields: [String]
    /// Whether is equivalent.
    public var isEquivalent: Bool

    /// Creates a new instance.
    public init(
        diff: BKRunSummaryDiff,
        tolerance: Double,
        comparedFieldCount: Int,
        changedFieldCount: Int,
        materiallyDifferentFields: [String],
        isEquivalent: Bool
    ) {
        self.diff = diff
        self.tolerance = tolerance
        self.comparedFieldCount = comparedFieldCount
        self.changedFieldCount = changedFieldCount
        self.materiallyDifferentFields = materiallyDifferentFields
        self.isEquivalent = isEquivalent
    }
}

/// Error emitted when two summaries are not equivalent within the supplied tolerance.
public struct BKComparisonAssertionError: LocalizedError, Equatable, Codable, Sendable {
    /// Detailed report associated with this value.
    public var report: BKRunComparisonReport

    /// Creates a new instance.
    public init(report: BKRunComparisonReport) {
        self.report = report
    }

    /// Localized description of the error.
    public var errorDescription: String? {
        let fields = report.materiallyDifferentFields.joined(separator: ", ")
        return "Runs are not equivalent within tolerance \(report.tolerance). Material differences: \(fields)"
    }
}

/// Validation-style readiness output for synthetic scenario workflows.
public struct BKScenarioReadinessReport: Codable, Equatable, Sendable {
    /// Configuration associated with this value.
    public var config: BKScenarioConfig
    /// Validation output associated with this value.
    public var validation: BKValidationReport
    /// Whether this value is ready for the next workflow step.
    public var isReady: Bool

    /// Creates a new instance.
    public init(
        config: BKScenarioConfig,
        validation: BKValidationReport,
        isReady: Bool
    ) {
        self.config = config
        self.validation = validation
        self.isReady = isReady
    }
}

/// One case inside a scenario smoke suite.
public struct BKScenarioSmokeCaseReport: Codable, Equatable, Sendable {
    /// Configuration associated with this value.
    public var config: BKScenarioConfig
    /// Readiness associated with this value.
    public var readiness: BKScenarioReadinessReport
    /// High-level summary associated with this value.
    public var summary: BKRunSummary?

    /// Creates a new instance.
    public init(
        config: BKScenarioConfig,
        readiness: BKScenarioReadinessReport,
        summary: BKRunSummary? = nil
    ) {
        self.config = config
        self.readiness = readiness
        self.summary = summary
    }
}

/// Aggregated output for deterministic scenario smoke suites.
public struct BKScenarioSmokeSuiteReport: Codable, Equatable, Sendable {
    /// Cases associated with this value.
    public var cases: [BKScenarioSmokeCaseReport]
    /// Passed case count represented by this value.
    public var passedCaseCount: Int
    /// Failed case count represented by this value.
    public var failedCaseCount: Int
    /// Whether the operation completed successfully.
    public var isSuccessful: Bool

    /// Creates a new instance.
    public init(
        cases: [BKScenarioSmokeCaseReport],
        passedCaseCount: Int,
        failedCaseCount: Int,
        isSuccessful: Bool
    ) {
        self.cases = cases
        self.passedCaseCount = passedCaseCount
        self.failedCaseCount = failedCaseCount
        self.isSuccessful = isSuccessful
    }
}
