import Foundation

/// Stable built-in manager-owned strategy recipes for helper workflows.
public enum BKStrategyRecipe: Codable, Equatable, Sendable {
    case smaCrossover(fast: Int = 5, slow: Int = 20)
    case emaFastSlow(
        fastPeriod: Int = 12,
        slowPeriod: Int = 26,
        atrPeriod: Int = 14,
        atrStopMultiplier: Double = 2.0
    )
    case rsi2MeanReversion(
        trendPeriod: Int = 200,
        entryThreshold: Double = 10,
        exitThreshold: Double = 60
    )
}

/// Result bundle for manager-level indicator composition helpers.
public struct BKIndicatorBundleResult: Codable, Equatable, Sendable {
    public var candles: [Candlestick]
    public var appliedIndicatorKeys: [String]

    /// Creates a new instance.
    public init(candles: [Candlestick], appliedIndicatorKeys: [String]) {
        self.candles = candles
        self.appliedIndicatorKeys = appliedIndicatorKeys
    }
}

/// Lightweight snapshot of a manager-built metrics report.
public struct BKManagerReportSnapshot: Codable, Equatable, Sendable {
    public var metrics: BKRunHeadlineMetrics
    public var tradeReturnCount: Int
    public var additiveEquityPointCount: Int
    public var compoundedEquityPointCount: Int

    /// Creates a new instance.
    public init(
        metrics: BKRunHeadlineMetrics,
        tradeReturnCount: Int,
        additiveEquityPointCount: Int,
        compoundedEquityPointCount: Int
    ) {
        self.metrics = metrics
        self.tradeReturnCount = tradeReturnCount
        self.additiveEquityPointCount = additiveEquityPointCount
        self.compoundedEquityPointCount = compoundedEquityPointCount
    }

    /// Creates a snapshot from an existing metrics report.
    public init(report: BacktestMetricsReport) {
        self.init(
            metrics: BKRunHeadlineMetrics(result: report.result),
            tradeReturnCount: report.tradeReturns.count,
            additiveEquityPointCount: report.additiveEquityCurve.count,
            compoundedEquityPointCount: report.compoundedEquityCurve.count
        )
    }
}

/// Report bundle produced by a manager-owned recipe workflow.
public struct BKStrategyRecipeReport {
    public var recipe: BKStrategyRecipe
    public var symbol: String
    public var result: BacktestResult
    public var summary: BKRunSummary
    public var snapshot: BKManagerReportSnapshot
    public var advancedMetrics: BKAdvancedPerformanceMetrics

    /// Creates a new instance.
    public init(
        recipe: BKStrategyRecipe,
        symbol: String,
        result: BacktestResult,
        summary: BKRunSummary,
        snapshot: BKManagerReportSnapshot,
        advancedMetrics: BKAdvancedPerformanceMetrics
    ) {
        self.recipe = recipe
        self.symbol = symbol
        self.result = result
        self.summary = summary
        self.snapshot = snapshot
        self.advancedMetrics = advancedMetrics
    }
}
