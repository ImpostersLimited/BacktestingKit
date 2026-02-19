import Foundation

/// Represents `BacktestMetricsReport` in the BacktestingKit public API.
public struct BacktestMetricsReport {
    public let result: BacktestResult
    public let totalCompoundedReturn: Double
    public let maxDrawdownPercent: Double
    public let averageDrawdownPercent: Double
    public let downsideDeviation: Double
    public let payoffRatio: Double
    public let recoveryFactor: Double
    public let tradeReturns: [Double]
    public let additiveEquityCurve: [Double]
    public let compoundedEquityCurve: [Double]

    /// Creates a new instance.
    public init(
        result: BacktestResult,
        totalCompoundedReturn: Double,
        maxDrawdownPercent: Double,
        averageDrawdownPercent: Double,
        downsideDeviation: Double,
        payoffRatio: Double,
        recoveryFactor: Double,
        tradeReturns: [Double],
        additiveEquityCurve: [Double],
        compoundedEquityCurve: [Double]
    ) {
        self.result = result
        self.totalCompoundedReturn = totalCompoundedReturn
        self.maxDrawdownPercent = maxDrawdownPercent
        self.averageDrawdownPercent = averageDrawdownPercent
        self.downsideDeviation = downsideDeviation
        self.payoffRatio = payoffRatio
        self.recoveryFactor = recoveryFactor
        self.tradeReturns = tradeReturns
        self.additiveEquityCurve = additiveEquityCurve
        self.compoundedEquityCurve = compoundedEquityCurve
    }
}
