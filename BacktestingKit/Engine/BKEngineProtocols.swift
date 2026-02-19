import Foundation

/// Unified protocol-oriented engine surface.
public protocol BKBacktestingEngine: BKIndicatorComputing, BKStrategyBacktesting, BKStrategyEvaluationReporting {}

/// Convenience existential for dependency injection.
public typealias BKAnyBacktestingEngine = BKIndicatorComputing & BKStrategyBacktesting & BKStrategyEvaluationReporting

/// Defines the `BKIndicatorComputing` contract used by BacktestingKit.
public protocol BKIndicatorComputing {
    func simpleMovingAverage(_ candles: [Candlestick], period: Int, name: String) -> [Candlestick]
    func exponentialMovingAverage(_ candles: [Candlestick], period: Int, uuid: String) -> [Candlestick]
    func relativeStrengthIndex(_ candles: [Candlestick], period: Int, uuid: String) -> [Candlestick]
    func macd(_ candles: [Candlestick], fast: Int, slow: Int, signal: Int, uuid: String) -> [Candlestick]
    func bollingerBands(_ candles: [Candlestick], period: Int, numStdDev: Double, uuid: String) -> [Candlestick]
}

/// Defines the `BKStrategyBacktesting` contract used by BacktestingKit.
public protocol BKStrategyBacktesting {
    func backtestSMACrossover(candles: [Candlestick], fast: Int, slow: Int) -> BacktestResult
    func backtest(
        candles: [Candlestick],
        uuid: String,
        indicators: [TechnicalIndicator],
        entrySignal: (_ prev: TechnicalIndicatorValueProvider, _ curr: TechnicalIndicatorValueProvider) -> Bool,
        exitSignal: (_ prev: TechnicalIndicatorValueProvider, _ curr: TechnicalIndicatorValueProvider, _ entry: TechnicalIndicatorValueProvider) -> Bool
    ) -> BacktestResult
    func backtest(
        candles: [Candlestick],
        indicators: [(name: String, indicator: TechnicalIndicator)],
        entryConditions: [StrategyCondition],
        exitConditions: [StrategyCondition]
    ) -> BacktestResult
}

/// Defines the `BKStrategyEvaluationReporting` contract used by BacktestingKit.
public protocol BKStrategyEvaluationReporting {
    func buildMetricsReport(trades: [Trade], candles: [Candlestick]) -> BacktestMetricsReport
    func buildMetricsReport(from result: BacktestResult, candles: [Candlestick]) -> BacktestMetricsReport
}
