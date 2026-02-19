import Foundation

/// Defines the `BKPositionSizingModel` contract used by BacktestingKit.
public protocol BKPositionSizingModel {
    func quantity(price: Double, accountEquity: Double, annualizedVolatility: Double) -> Double
}

/// Represents `BKVolatilityTargetingSizer` in the BacktestingKit public API.
public struct BKVolatilityTargetingSizer: BKPositionSizingModel {
    public let targetAnnualizedVolatility: Double
    public let maxGrossLeverage: Double

    /// Creates a new instance.
    public init(targetAnnualizedVolatility: Double = 0.15, maxGrossLeverage: Double = 2.0) {
        self.targetAnnualizedVolatility = max(0.0001, targetAnnualizedVolatility)
        self.maxGrossLeverage = max(0.1, maxGrossLeverage)
    }

    /// Executes `quantity`.
    public func quantity(price: Double, accountEquity: Double, annualizedVolatility: Double) -> Double {
        guard price > 0, accountEquity > 0, annualizedVolatility > 0 else { return 0 }
        let targetWeight = min(maxGrossLeverage, targetAnnualizedVolatility / annualizedVolatility)
        let notional = accountEquity * targetWeight
        return notional / price
    }
}

/// Represents `BKFixedFractionalSizer` in the BacktestingKit public API.
public struct BKFixedFractionalSizer: BKPositionSizingModel {
    public let riskFraction: Double
    public let fallbackRiskPerUnitFraction: Double

    /// Creates a new instance.
    public init(riskFraction: Double = 0.01, fallbackRiskPerUnitFraction: Double = 0.02) {
        self.riskFraction = min(max(riskFraction, 0), 1)
        self.fallbackRiskPerUnitFraction = max(fallbackRiskPerUnitFraction, 0.0001)
    }

    /// Executes `quantity`.
    public func quantity(price: Double, accountEquity: Double, annualizedVolatility: Double) -> Double {
        guard price > 0, accountEquity > 0 else { return 0 }
        let perUnitRisk = max(price * fallbackRiskPerUnitFraction, price * max(annualizedVolatility, 0.0001) / sqrt(252.0))
        let riskBudget = accountEquity * riskFraction
        return riskBudget / perUnitRisk
    }
}

/// Represents `BKKellyCappedSizer` in the BacktestingKit public API.
public struct BKKellyCappedSizer: BKPositionSizingModel {
    public let expectedReturn: Double
    public let returnVariance: Double
    public let maxWeight: Double

    /// Creates a new instance.
    public init(expectedReturn: Double = 0.10, returnVariance: Double = 0.04, maxWeight: Double = 0.30) {
        self.expectedReturn = expectedReturn
        self.returnVariance = max(returnVariance, 0.0001)
        self.maxWeight = min(max(maxWeight, 0), 1)
    }

    /// Executes `quantity`.
    public func quantity(price: Double, accountEquity: Double, annualizedVolatility _: Double) -> Double {
        guard price > 0, accountEquity > 0 else { return 0 }
        let rawKelly = expectedReturn / returnVariance
        let cappedWeight = min(max(rawKelly, 0), maxWeight)
        return (accountEquity * cappedWeight) / price
    }
}
