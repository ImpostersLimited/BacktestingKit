import Foundation

/// Represents `BacktestMetricsReport` in the BacktestingKit public API.
public struct BacktestMetricsReport {
    /// Result associated with this value.
    public let result: BacktestResult
    /// Total compounded return represented by this value.
    public let totalCompoundedReturn: Double
    /// Maximum drawdown percent associated with this value.
    public let maxDrawdownPercent: Double
    /// Average drawdown percent associated with this value.
    public let averageDrawdownPercent: Double
    /// Downside deviation associated with this value.
    public let downsideDeviation: Double
    /// Payoff ratio associated with this value.
    public let payoffRatio: Double
    /// Recovery factor associated with this value.
    public let recoveryFactor: Double
    /// Trade returns associated with this value.
    public let tradeReturns: [Double]
    /// Additive equity curve associated with this value.
    public let additiveEquityCurve: [Double]
    /// Compounded equity curve associated with this value.
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
