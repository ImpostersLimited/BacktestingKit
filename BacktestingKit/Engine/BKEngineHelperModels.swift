import Foundation

/// Presentation-friendly headline metrics derived from a backtest result.
public struct BKRunHeadlineMetrics: Codable, Equatable, Sendable {
    public var tradeCount: Int
    public var winRate: Double
    public var totalReturn: Double
    public var annualizedReturn: Double
    public var maxDrawdown: Double
    public var sharpeRatio: Double
    public var profitFactor: Double

    /// Creates a new instance.
    public init(
        tradeCount: Int,
        winRate: Double,
        totalReturn: Double,
        annualizedReturn: Double,
        maxDrawdown: Double,
        sharpeRatio: Double,
        profitFactor: Double
    ) {
        self.tradeCount = tradeCount
        self.winRate = winRate
        self.totalReturn = totalReturn
        self.annualizedReturn = annualizedReturn
        self.maxDrawdown = maxDrawdown
        self.sharpeRatio = sharpeRatio
        self.profitFactor = profitFactor
    }

    /// Creates headline metrics from an existing backtest result.
    public init(result: BacktestResult) {
        self.init(
            tradeCount: result.numTrades,
            winRate: result.winRate,
            totalReturn: result.totalReturn,
            annualizedReturn: result.annualizedReturn,
            maxDrawdown: result.maxDrawdown,
            sharpeRatio: result.sharpeRatio,
            profitFactor: result.profitFactor
        )
    }

    /// Creates headline metrics from a legacy analysis payload.
    /// Values that are not represented in the analysis model default to `0`.
    public init(analysis: BKAnalysis) {
        self.init(
            tradeCount: analysis.totalTrades,
            winRate: analysis.percentProfitable / 100.0,
            totalReturn: analysis.profitPct / 100.0,
            annualizedReturn: 0,
            maxDrawdown: analysis.maxDrawdownPct / 100.0,
            sharpeRatio: 0,
            profitFactor: analysis.profitFactor ?? 0
        )
    }

    /// Creates headline metrics from a v2 analysis payload.
    /// Values that are not represented in the analysis model default to `0`.
    public init(v2Analysis: BKV2.BKAnalysis) {
        self.init(
            tradeCount: Int(v2Analysis.totalTrades),
            winRate: v2Analysis.percentProfitable / 100.0,
            totalReturn: v2Analysis.profitPct / 100.0,
            annualizedReturn: 0,
            maxDrawdown: v2Analysis.maxDrawdownPct / 100.0,
            sharpeRatio: 0,
            profitFactor: v2Analysis.profitFactor ?? 0
        )
    }
}

/// Compact run summary suitable for onboarding flows and smoke-test output.
public struct BKRunSummary: Codable, Equatable, Sendable {
    public var symbol: String
    public var barCount: Int
    public var startDate: Date?
    public var endDate: Date?
    public var metrics: BKRunHeadlineMetrics

    /// Creates a new instance.
    public init(
        symbol: String,
        barCount: Int,
        startDate: Date? = nil,
        endDate: Date? = nil,
        metrics: BKRunHeadlineMetrics
    ) {
        self.symbol = symbol
        self.barCount = barCount
        self.startDate = startDate
        self.endDate = endDate
        self.metrics = metrics
    }
}

/// Preflight-aware preset run result for inline CSV onboarding workflows.
public struct BKPreflightedRunSummary {
    public var symbol: String
    public var preset: BKPresetCatalog
    public var preflight: BKToolPreflightReport
    public var summary: BKRunSummary?
    public var failure: BKEngineFailure?
    public var isSuccessful: Bool

    /// Creates a new instance.
    public init(
        symbol: String,
        preset: BKPresetCatalog,
        preflight: BKToolPreflightReport,
        summary: BKRunSummary? = nil,
        failure: BKEngineFailure? = nil,
        isSuccessful: Bool
    ) {
        self.symbol = symbol
        self.preset = preset
        self.preflight = preflight
        self.summary = summary
        self.failure = failure
        self.isSuccessful = isSuccessful
    }
}

/// Structured validation + execution result for v2 inline CSV workflows.
public struct BKV2ValidatedRunReport {
    public var instrumentID: String
    public var preflight: BKToolPreflightReport
    public var requestValidation: BKValidationReport
    public var output: BKV2.SimulateConfigOutput?
    public var positionStatus: PositionStatus?
    public var failure: BKEngineFailure?
    public var isSuccessful: Bool

    /// Creates a new instance.
    public init(
        instrumentID: String,
        preflight: BKToolPreflightReport,
        requestValidation: BKValidationReport,
        output: BKV2.SimulateConfigOutput? = nil,
        positionStatus: PositionStatus? = nil,
        failure: BKEngineFailure? = nil,
        isSuccessful: Bool
    ) {
        self.instrumentID = instrumentID
        self.preflight = preflight
        self.requestValidation = requestValidation
        self.output = output
        self.positionStatus = positionStatus
        self.failure = failure
        self.isSuccessful = isSuccessful
    }
}

/// Structured validation + execution result for v3 inline CSV workflows.
public struct BKV3ValidatedRunReport {
    public var instrumentID: String
    public var preflight: BKToolPreflightReport
    public var requestValidation: BKValidationReport
    public var report: BKSimulationInstrumentReport?
    public var failure: BKEngineFailure?
    public var isSuccessful: Bool

    /// Creates a new instance.
    public init(
        instrumentID: String,
        preflight: BKToolPreflightReport,
        requestValidation: BKValidationReport,
        report: BKSimulationInstrumentReport? = nil,
        failure: BKEngineFailure? = nil,
        isSuccessful: Bool
    ) {
        self.instrumentID = instrumentID
        self.preflight = preflight
        self.requestValidation = requestValidation
        self.report = report
        self.failure = failure
        self.isSuccessful = isSuccessful
    }
}
