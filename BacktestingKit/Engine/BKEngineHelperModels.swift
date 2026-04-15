import Foundation

/// Presentation-friendly headline metrics derived from a backtest result.
public struct BKRunHeadlineMetrics: Codable, Equatable, Sendable {
    /// Number of trades represented by this value.
    public var tradeCount: Int
    /// Win rate associated with this value.
    public var winRate: Double
    /// Total return represented by this value.
    public var totalReturn: Double
    /// Annualized return associated with this value.
    public var annualizedReturn: Double
    /// Maximum drawdown associated with this value.
    public var maxDrawdown: Double
    /// Sharpe ratio associated with this value.
    public var sharpeRatio: Double
    /// Profit factor associated with this value.
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
    /// Ticker symbol associated with this value.
    public var symbol: String
    /// Number of bars represented by this value.
    public var barCount: Int
    /// Start date represented by this value.
    public var startDate: Date?
    /// End date represented by this value.
    public var endDate: Date?
    /// Headline metrics associated with this value.
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
    /// Ticker symbol associated with this value.
    public var symbol: String
    /// Preset associated with this value.
    public var preset: BKPresetCatalog
    /// Preflight validation output associated with this value.
    public var preflight: BKToolPreflightReport
    /// High-level summary associated with this value.
    public var summary: BKRunSummary?
    /// Typed failure associated with this value when execution does not succeed.
    public var failure: BKEngineFailure?
    /// Whether the operation completed successfully.
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
    /// Identifier associated with this value.
    public var instrumentID: String
    /// Preflight validation output associated with this value.
    public var preflight: BKToolPreflightReport
    /// Request validation associated with this value.
    public var requestValidation: BKValidationReport
    /// Output associated with this value.
    public var output: BKV2.SimulateConfigOutput?
    /// Position status associated with this value.
    public var positionStatus: PositionStatus?
    /// Typed failure associated with this value when execution does not succeed.
    public var failure: BKEngineFailure?
    /// Whether the operation completed successfully.
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
    /// Identifier associated with this value.
    public var instrumentID: String
    /// Preflight validation output associated with this value.
    public var preflight: BKToolPreflightReport
    /// Request validation associated with this value.
    public var requestValidation: BKValidationReport
    /// Detailed report associated with this value.
    public var report: BKSimulationInstrumentReport?
    /// Typed failure associated with this value when execution does not succeed.
    public var failure: BKEngineFailure?
    /// Whether the operation completed successfully.
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
