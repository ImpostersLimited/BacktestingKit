import Foundation

public struct BKExecutionPresetProfile {
    public let slippageModel: BKSlippageModel
    public let commissionModel: BKCommissionModel

    /// Creates a custom execution profile.
    ///
    /// - Parameters:
    ///   - slippageModel: Slippage model applied to entry/exit fills.
    ///   - commissionModel: Commission model applied per trade leg.
    public init(slippageModel: BKSlippageModel, commissionModel: BKCommissionModel) {
        self.slippageModel = slippageModel
        self.commissionModel = commissionModel
    }
}

public extension BKExecutionPresetProfile {
    /// Retail-oriented default assumptions (5 bps slippage, fixed+percent commission).
    static var retailRealistic: BKExecutionPresetProfile {
        BKExecutionPresetProfile(
            slippageModel: BKFixedBpsSlippageModel(bps: 5),
            commissionModel: BKFixedPlusPercentCommissionModel(fixedPerOrder: 1.0, percentOfNotional: 0.0005)
        )
    }
}

/// Wrapper for reusable position-sizing model profiles.
public struct BKPositionSizingPresetProfile {
    public let sizingModel: BKPositionSizingModel

    /// Creates a custom position-sizing profile.
    ///
    /// - Parameter sizingModel: Position sizing model to expose via preset profile.
    public init(sizingModel: BKPositionSizingModel) {
        self.sizingModel = sizingModel
    }
}

public extension BKPositionSizingPresetProfile {
    /// Volatility-target profile targeting ~15% annualized risk.
    static var volatilityTarget15Pct: BKPositionSizingPresetProfile {
        BKPositionSizingPresetProfile(
            sizingModel: BKVolatilityTargetingSizer(targetAnnualizedVolatility: 0.15, maxGrossLeverage: 2.0)
        )
    }

    /// Fixed fractional sizing profile at 1% risk budget.
    static var fixedFractional1Pct: BKPositionSizingPresetProfile {
        BKPositionSizingPresetProfile(
            sizingModel: BKFixedFractionalSizer(riskFraction: 0.01, fallbackRiskPerUnitFraction: 0.02)
        )
    }

    /// Kelly-based sizing profile capped at 30% portfolio weight.
    static var kellyCapped30Pct: BKPositionSizingPresetProfile {
        BKPositionSizingPresetProfile(
            sizingModel: BKKellyCappedSizer(expectedReturn: 0.10, returnVariance: 0.04, maxWeight: 0.30)
        )
    }
}

/// Prebuilt stop/risk policy bundles for strategy-level composition.
public struct BKRiskControlPresetProfile {
    public let atrPeriod: Int
    public let atrStopMultiplier: Double
    public let useTrailingStop: Bool
    public let maxHoldingBars: Int?

    /// Creates a new instance.
    public init(
        atrPeriod: Int = 14,
        atrStopMultiplier: Double = 2.0,
        useTrailingStop: Bool = true,
        maxHoldingBars: Int? = nil
    ) {
        self.atrPeriod = max(1, atrPeriod)
        self.atrStopMultiplier = max(0.1, atrStopMultiplier)
        self.useTrailingStop = useTrailingStop
        self.maxHoldingBars = maxHoldingBars
    }
}

public extension BKRiskControlPresetProfile {
    /// Time-stop + ATR stop + trailing-stop policy bundle.
    static var timeStopAtrTrailing: BKRiskControlPresetProfile {
        BKRiskControlPresetProfile(
            atrPeriod: 14,
            atrStopMultiplier: 2.0,
            useTrailingStop: true,
            maxHoldingBars: 20
        )
    }
}

/// Evaluation preset bundle for walk-forward and stability-oriented runs.
public struct BKEvaluationPresetProfile {
    public let walkForwardFolds: Int
    public let inSampleRatio: Double
    public let includeOutOfSampleStabilityScore: Bool
    public let bootstrapRuns: Int

    /// Creates a new instance.
    public init(
        walkForwardFolds: Int = 6,
        inSampleRatio: Double = 0.7,
        includeOutOfSampleStabilityScore: Bool = true,
        bootstrapRuns: Int = 500
    ) {
        self.walkForwardFolds = max(2, walkForwardFolds)
        self.inSampleRatio = min(max(inSampleRatio, 0.5), 0.9)
        self.includeOutOfSampleStabilityScore = includeOutOfSampleStabilityScore
        self.bootstrapRuns = max(50, bootstrapRuns)
    }
}

public extension BKEvaluationPresetProfile {
    /// Walk-forward validation profile with out-of-sample stability tracking.
    static var walkForwardStability: BKEvaluationPresetProfile {
        BKEvaluationPresetProfile(
            walkForwardFolds: 6,
            inSampleRatio: 0.7,
            includeOutOfSampleStabilityScore: true,
            bootstrapRuns: 500
        )
    }
}

/// Portfolio-level helper presets.
public enum BKPortfolioPresets {
    /// Computes normalized inverse-volatility weights.
    ///
    /// - Parameter annualizedVolatilities: Per-asset annualized volatility values.
    /// - Returns: Weights summing to `1.0` when possible, otherwise equal weights fallback.
    public static func riskParityWeights(annualizedVolatilities: [Double]) -> [Double] {
        guard !annualizedVolatilities.isEmpty else { return [] }
        let inverseRisk = annualizedVolatilities.map { vol -> Double in
            guard vol > 0 else { return 0 }
            return 1.0 / vol
        }
        let total = inverseRisk.reduce(0, +)
        guard total > 0 else {
            let equalWeight = 1.0 / Double(annualizedVolatilities.count)
            return Array(repeating: equalWeight, count: annualizedVolatilities.count)
        }
        return inverseRisk.map { $0 / total }
    }

    /// Risk-on / risk-off two-asset weighting preset based on relative momentum scores.
    ///
    /// - Parameters:
    ///   - riskOnMomentum: Momentum score of risk-on sleeve (e.g., equities).
    ///   - riskOffMomentum: Momentum score of defensive sleeve (e.g., bonds/cash proxy).
    /// - Returns: Two weights `[riskOn, riskOff]` summing to `1.0`.
    public static func riskOnRiskOffWeights(riskOnMomentum: Double, riskOffMomentum: Double) -> [Double] {
        if riskOnMomentum.isNaN || riskOffMomentum.isNaN {
            return [0.5, 0.5]
        }
        if riskOnMomentum > riskOffMomentum {
            return [0.8, 0.2]
        }
        if riskOnMomentum < riskOffMomentum {
            return [0.2, 0.8]
        }
        return [0.5, 0.5]
    }
}
