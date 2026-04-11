import Foundation

/// Aggregated output from a helper-driven CSV preflight workflow.
public struct BKToolPreflightReport: Codable, Equatable, Sendable {
    public var symbol: String?
    public var rowCount: Int?
    public var startDate: Date?
    public var endDate: Date?
    public var validation: BKValidationReport
    public var diagnostics: [BKDiagnosticEvent]
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
    public var preflightJSON: String
    public var diagnosticsJSON: String?
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
    public var eventCount: Int
    public var firstTimestamp: Date?
    public var lastTimestamp: Date?
    public var stageCounts: [String: Int]
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
    public var summaryJSON: String
    public var diagnosticsSummaryJSON: String?
    public var tradesCSV: String?
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
    public var baseline: BKRunHeadlineMetrics
    public var candidate: BKRunHeadlineMetrics
    public var tradeCountDelta: Int
    public var winRateDelta: Double
    public var totalReturnDelta: Double
    public var annualizedReturnDelta: Double
    public var maxDrawdownDelta: Double
    public var sharpeRatioDelta: Double
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
    public var baseline: BKRunSummary
    public var candidate: BKRunSummary
    public var symbolChanged: Bool
    public var barCountDelta: Int
    public var startDateChanged: Bool
    public var endDateChanged: Bool
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
    public var diff: BKRunSummaryDiff
    public var tolerance: Double
    public var comparedFieldCount: Int
    public var changedFieldCount: Int
    public var materiallyDifferentFields: [String]
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
    public var report: BKRunComparisonReport

    /// Creates a new instance.
    public init(report: BKRunComparisonReport) {
        self.report = report
    }

    public var errorDescription: String? {
        let fields = report.materiallyDifferentFields.joined(separator: ", ")
        return "Runs are not equivalent within tolerance \(report.tolerance). Material differences: \(fields)"
    }
}

/// Validation-style readiness output for synthetic scenario workflows.
public struct BKScenarioReadinessReport: Codable, Equatable, Sendable {
    public var config: BKScenarioConfig
    public var validation: BKValidationReport
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
    public var config: BKScenarioConfig
    public var readiness: BKScenarioReadinessReport
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
    public var cases: [BKScenarioSmokeCaseReport]
    public var passedCaseCount: Int
    public var failedCaseCount: Int
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
