import Foundation

public struct BKAnalysis: Codable, Equatable {
    public var BKMaxDownDraw: Double
    public var BKMaxDownDrawPct: Double
    public var startingCapital: Double
    public var finalCapital: Double
    public var profit: Double
    public var profitPct: Double
    public var growth: Double
    public var totalTrades: Int
    public var barCount: Int
    public var maxDrawdown: Double
    public var maxDrawdownPct: Double
    public var maxRiskPct: Double?
    public var expectency: Double
    public var rmultipleStdDev: Double
    public var systemQuality: Double?
    public var profitFactor: Double?
    public var proportionProfitable: Double
    public var percentProfitable: Double
    public var returnOnAccount: Double
    public var averageProfitPerTrade: Double
    public var numWinningTrades: Int
    public var numLosingTrades: Int
    public var averageWinningTrade: Double
    public var averageLosingTrade: Double
    public var expectedValue: Double

    /// Creates a new instance.
    public init(
        BKMaxDownDraw: Double = 0,
        BKMaxDownDrawPct: Double = 0,
        startingCapital: Double = 0,
        finalCapital: Double = 0,
        profit: Double = 0,
        profitPct: Double = 0,
        growth: Double = 0,
        totalTrades: Int = 0,
        barCount: Int = 0,
        maxDrawdown: Double = 0,
        maxDrawdownPct: Double = 0,
        maxRiskPct: Double? = 0,
        expectency: Double = 0,
        rmultipleStdDev: Double = 0,
        systemQuality: Double? = 0,
        profitFactor: Double? = 0,
        proportionProfitable: Double = 0,
        percentProfitable: Double = 0,
        returnOnAccount: Double = 0,
        averageProfitPerTrade: Double = 0,
        numWinningTrades: Int = 0,
        numLosingTrades: Int = 0,
        averageWinningTrade: Double = 0,
        averageLosingTrade: Double = 0,
        expectedValue: Double = 0
    ) {
        self.BKMaxDownDraw = BKMaxDownDraw
        self.BKMaxDownDrawPct = BKMaxDownDrawPct
        self.startingCapital = startingCapital
        self.finalCapital = finalCapital
        self.profit = profit
        self.profitPct = profitPct
        self.growth = growth
        self.totalTrades = totalTrades
        self.barCount = barCount
        self.maxDrawdown = maxDrawdown
        self.maxDrawdownPct = maxDrawdownPct
        self.maxRiskPct = maxRiskPct
        self.expectency = expectency
        self.rmultipleStdDev = rmultipleStdDev
        self.systemQuality = systemQuality
        self.profitFactor = profitFactor
        self.proportionProfitable = proportionProfitable
        self.percentProfitable = percentProfitable
        self.returnOnAccount = returnOnAccount
        self.averageProfitPerTrade = averageProfitPerTrade
        self.numWinningTrades = numWinningTrades
        self.numLosingTrades = numLosingTrades
        self.averageWinningTrade = averageWinningTrade
        self.averageLosingTrade = averageLosingTrade
        self.expectedValue = expectedValue
    }
}

/// Represents `BKTimestampedValue` in the BacktestingKit public API.
public struct BKTimestampedValue: Codable, Equatable {
    public var time: Date
    public var value: Double

    /// Creates a new instance.
    public init(time: Date, value: Double) {
        self.time = time
        self.value = value
    }
}

/// Represents `BKTrade` in the BacktestingKit public API.
public struct BKTrade: Codable, Equatable {
    public var direction: TradeDirection
    public var entryTime: Date
    public var entryPrice: Double
    public var exitTime: Date
    public var exitPrice: Double
    public var profit: Double
    public var profitPct: Double
    public var growth: Double
    public var riskPct: Double
    public var rmultiple: Double
    public var riskSeries: [BKTimestampedValue]
    public var holdingPeriod: Int
    public var exitReason: String
    public var stopPrice: Double
    public var stopPriceSeries: [BKTimestampedValue]
    public var profitTarget: Double

    /// Creates a new instance.
    public init(
        direction: TradeDirection,
        entryTime: Date,
        entryPrice: Double,
        exitTime: Date,
        exitPrice: Double,
        profit: Double,
        profitPct: Double,
        growth: Double,
        riskPct: Double = 0,
        rmultiple: Double = 0,
        riskSeries: [BKTimestampedValue] = [],
        holdingPeriod: Int,
        exitReason: String,
        stopPrice: Double = 0,
        stopPriceSeries: [BKTimestampedValue] = [],
        profitTarget: Double = 0
    ) {
        self.direction = direction
        self.entryTime = entryTime
        self.entryPrice = entryPrice
        self.exitTime = exitTime
        self.exitPrice = exitPrice
        self.profit = profit
        self.profitPct = profitPct
        self.growth = growth
        self.riskPct = riskPct
        self.rmultiple = rmultiple
        self.riskSeries = riskSeries
        self.holdingPeriod = holdingPeriod
        self.exitReason = exitReason
        self.stopPrice = stopPrice
        self.stopPriceSeries = stopPriceSeries
        self.profitTarget = profitTarget
    }
}

/// Represents `SimulationRule` in the BacktestingKit public API.
public struct SimulationRule: Codable, Equatable {
    public var indicatorOneName: String
    public var indicatorOneType: TechnicalIndicators
    public var indicatorOneFigure: [Double]
    public var compare: CompareOption
    public var indicatorTwoName: String
    public var indicatorTwoType: TechnicalIndicators
    public var indicatorTwoFigure: [Double]

    /// Creates a new instance.
    public init(
        indicatorOneName: String,
        indicatorOneType: TechnicalIndicators,
        indicatorOneFigure: [Double],
        compare: CompareOption,
        indicatorTwoName: String,
        indicatorTwoType: TechnicalIndicators,
        indicatorTwoFigure: [Double]
    ) {
        self.indicatorOneName = indicatorOneName
        self.indicatorOneType = indicatorOneType
        self.indicatorOneFigure = indicatorOneFigure
        self.compare = compare
        self.indicatorTwoName = indicatorTwoName
        self.indicatorTwoType = indicatorTwoType
        self.indicatorTwoFigure = indicatorTwoFigure
    }
}

/// Represents `SimulationPolicyConfig` in the BacktestingKit public API.
public struct SimulationPolicyConfig: Codable, Equatable {
    public var policy: SimulationPolicy
    public var trailingStopLoss: Bool
    public var stopLossFigure: Double
    public var profitFactor: Double
    public var entryRules: [SimulationRule]
    public var exitRules: [SimulationRule]
    public var t1: Double
    public var t2: Double

    /// Creates a new instance.
    public init(
        policy: SimulationPolicy,
        trailingStopLoss: Bool,
        stopLossFigure: Double,
        profitFactor: Double,
        entryRules: [SimulationRule],
        exitRules: [SimulationRule],
        t1: Double,
        t2: Double
    ) {
        self.policy = policy
        self.trailingStopLoss = trailingStopLoss
        self.stopLossFigure = stopLossFigure
        self.profitFactor = profitFactor
        self.entryRules = entryRules
        self.exitRules = exitRules
        self.t1 = t1
        self.t2 = t2
    }
}

/// Represents `OptimizePolicyConfig` in the BacktestingKit public API.
public struct OptimizePolicyConfig: Codable, Equatable {
    public var stepSize: Double
    public var simplePolicy: Bool
    public var trailingStopLoss: Bool
    public var stopLossFigure: Double
    public var profitFactor: Double
    public var entryRules: [OptimizeRule]
    public var exitRules: [OptimizeRule]
    public var t1: Double
    public var t2: Double

    /// Creates a new instance.
    public init(
        stepSize: Double,
        simplePolicy: Bool,
        trailingStopLoss: Bool,
        stopLossFigure: Double,
        profitFactor: Double,
        entryRules: [OptimizeRule],
        exitRules: [OptimizeRule],
        t1: Double,
        t2: Double
    ) {
        self.stepSize = stepSize
        self.simplePolicy = simplePolicy
        self.trailingStopLoss = trailingStopLoss
        self.stopLossFigure = stopLossFigure
        self.profitFactor = profitFactor
        self.entryRules = entryRules
        self.exitRules = exitRules
        self.t1 = t1
        self.t2 = t2
    }
}

/// Represents `OptimizeRule` in the BacktestingKit public API.
public struct OptimizeRule: Codable, Equatable {
    public var indicatorOneName: String
    public var indicatorOneType: TechnicalIndicators
    public var indicatorOneFigureLower: [Double]
    public var indicatorOneFigureUpper: [Double]
    public var compare: CompareOption
    public var indicatorTwoName: String
    public var indicatorTwoType: TechnicalIndicators
    public var indicatorTwoFigureLower: [Double]
    public var indicatorTwoFigureUpper: [Double]

    /// Creates a new instance.
    public init(
        indicatorOneName: String,
        indicatorOneType: TechnicalIndicators,
        indicatorOneFigureLower: [Double],
        indicatorOneFigureUpper: [Double],
        compare: CompareOption,
        indicatorTwoName: String,
        indicatorTwoType: TechnicalIndicators,
        indicatorTwoFigureLower: [Double],
        indicatorTwoFigureUpper: [Double]
    ) {
        self.indicatorOneName = indicatorOneName
        self.indicatorOneType = indicatorOneType
        self.indicatorOneFigureLower = indicatorOneFigureLower
        self.indicatorOneFigureUpper = indicatorOneFigureUpper
        self.compare = compare
        self.indicatorTwoName = indicatorTwoName
        self.indicatorTwoType = indicatorTwoType
        self.indicatorTwoFigureLower = indicatorTwoFigureLower
        self.indicatorTwoFigureUpper = indicatorTwoFigureUpper
    }
}

/// Represents `OptimizeRulesContainer` in the BacktestingKit public API.
public struct OptimizeRulesContainer: Codable, Equatable {
    public var rules: [String: [SimulationRule]]

    /// Creates a new instance.
    public init(rules: [String: [SimulationRule]]) {
        self.rules = rules
    }
}

/// Represents `User` in the BacktestingKit public API.
