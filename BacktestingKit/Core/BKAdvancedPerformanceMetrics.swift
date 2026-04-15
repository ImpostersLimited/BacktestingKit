import Foundation

/// Represents `BKAdvancedPerformanceMetrics` in the BacktestingKit public API.
public struct BKAdvancedPerformanceMetrics: Equatable, Codable {
    /// MAR ratio associated with this value.
    public let marRatio: Double
    /// Omega ratio associated with this value.
    public let omegaRatio: Double
    /// Skewness associated with this value.
    public let skewness: Double
    /// Kurtosis associated with this value.
    public let kurtosis: Double
    /// Tail ratio associated with this value.
    public let tailRatio: Double
    /// Var95 associated with this value.
    public let var95: Double
    /// Cvar95 associated with this value.
    public let cvar95: Double
    /// Exposure percent associated with this value.
    public let exposurePercent: Double
    /// Turnover approx associated with this value.
    public let turnoverApprox: Double
    /// Average trade duration days associated with this value.
    public let averageTradeDurationDays: Double
    /// Time under water percent associated with this value.
    public let timeUnderWaterPercent: Double

    /// Creates a new instance.
    public init(
        marRatio: Double,
        omegaRatio: Double,
        skewness: Double,
        kurtosis: Double,
        tailRatio: Double,
        var95: Double,
        cvar95: Double,
        exposurePercent: Double,
        turnoverApprox: Double,
        averageTradeDurationDays: Double,
        timeUnderWaterPercent: Double
    ) {
        self.marRatio = marRatio
        self.omegaRatio = omegaRatio
        self.skewness = skewness
        self.kurtosis = kurtosis
        self.tailRatio = tailRatio
        self.var95 = var95
        self.cvar95 = cvar95
        self.exposurePercent = exposurePercent
        self.turnoverApprox = turnoverApprox
        self.averageTradeDurationDays = averageTradeDurationDays
        self.timeUnderWaterPercent = timeUnderWaterPercent
    }
}
