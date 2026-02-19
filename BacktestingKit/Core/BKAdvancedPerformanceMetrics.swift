import Foundation

/// Represents `BKAdvancedPerformanceMetrics` in the BacktestingKit public API.
public struct BKAdvancedPerformanceMetrics: Equatable, Codable {
    public let marRatio: Double
    public let omegaRatio: Double
    public let skewness: Double
    public let kurtosis: Double
    public let tailRatio: Double
    public let var95: Double
    public let cvar95: Double
    public let exposurePercent: Double
    public let turnoverApprox: Double
    public let averageTradeDurationDays: Double
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
