import Foundation

/// Summary statistics produced by a completed backtest run.
public struct BKAnalysis: Codable, Equatable {
    /// Backtest maximum down draw associated with this value.
    public var BKMaxDownDraw: Double
    /// Backtest maximum down draw percentage associated with this value.
    public var BKMaxDownDrawPct: Double
    /// Starting capital associated with this value.
    public var startingCapital: Double
    /// Final capital associated with this value.
    public var finalCapital: Double
    /// Profit associated with this value.
    public var profit: Double
    /// Profit percentage associated with this value.
    public var profitPct: Double
    /// Growth associated with this value.
    public var growth: Double
    /// Total trades represented by this value.
    public var totalTrades: Int
    /// Number of bars represented by this value.
    public var barCount: Int
    /// Maximum drawdown associated with this value.
    public var maxDrawdown: Double
    /// Maximum drawdown percentage associated with this value.
    public var maxDrawdownPct: Double
    /// Maximum risk percentage associated with this value.
    public var maxRiskPct: Double?
    /// Expectency associated with this value.
    public var expectency: Double
    /// Rmultiple standard deviation associated with this value.
    public var rmultipleStdDev: Double
    /// System quality associated with this value.
    public var systemQuality: Double?
    /// Profit factor associated with this value.
    public var profitFactor: Double?
    /// Proportion profitable associated with this value.
    public var proportionProfitable: Double
    /// Percent profitable associated with this value.
    public var percentProfitable: Double
    /// Return on account represented by this value.
    public var returnOnAccount: Double
    /// Average profit per trade associated with this value.
    public var averageProfitPerTrade: Double
    /// Number winning trades represented by this value.
    public var numWinningTrades: Int
    /// Number losing trades represented by this value.
    public var numLosingTrades: Int
    /// Average winning trade associated with this value.
    public var averageWinningTrade: Double
    /// Average losing trade associated with this value.
    public var averageLosingTrade: Double
    /// Expected value associated with this value.
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
    /// Timestamp associated with this value.
    public var time: Date
    /// Value associated with this value.
    public var value: Double

    /// Creates a new instance.
    public init(time: Date, value: Double) {
        self.time = time
        self.value = value
    }
}

/// Represents `BKTrade` in the BacktestingKit public API.
public struct BKTrade: Codable, Equatable {
    /// Direction associated with this value.
    public var direction: TradeDirection
    /// Entry time associated with this value.
    public var entryTime: Date
    /// Entry price associated with this value.
    public var entryPrice: Double
    /// Exit time associated with this value.
    public var exitTime: Date
    /// Exit price associated with this value.
    public var exitPrice: Double
    /// Profit associated with this value.
    public var profit: Double
    /// Profit percentage associated with this value.
    public var profitPct: Double
    /// Growth associated with this value.
    public var growth: Double
    /// Risk percentage associated with this value.
    public var riskPct: Double
    /// Rmultiple associated with this value.
    public var rmultiple: Double
    /// Risk series associated with this value.
    public var riskSeries: [BKTimestampedValue]
    /// Holding period associated with this value.
    public var holdingPeriod: Int
    /// Exit reason associated with this value.
    public var exitReason: String
    /// Stop price associated with this value.
    public var stopPrice: Double
    /// Stop price series associated with this value.
    public var stopPriceSeries: [BKTimestampedValue]
    /// Profit target associated with this value.
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
    /// Indicator one name associated with this value.
    public var indicatorOneName: String
    /// Indicator one type associated with this value.
    public var indicatorOneType: TechnicalIndicators
    /// Indicator one figure associated with this value.
    public var indicatorOneFigure: [Double]
    /// Compare associated with this value.
    public var compare: CompareOption
    /// Indicator two name associated with this value.
    public var indicatorTwoName: String
    /// Indicator two type associated with this value.
    public var indicatorTwoType: TechnicalIndicators
    /// Indicator two figure associated with this value.
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
    /// Policy associated with this value.
    public var policy: SimulationPolicy
    /// Trailing stop loss associated with this value.
    public var trailingStopLoss: Bool
    /// Stop loss figure associated with this value.
    public var stopLossFigure: Double
    /// Profit factor associated with this value.
    public var profitFactor: Double
    /// Rules associated with this value.
    public var entryRules: [SimulationRule]
    /// Rules associated with this value.
    public var exitRules: [SimulationRule]
    /// T1 associated with this value.
    public var t1: Double
    /// T2 associated with this value.
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
    /// Step size associated with this value.
    public var stepSize: Double
    /// Simple policy associated with this value.
    public var simplePolicy: Bool
    /// Trailing stop loss associated with this value.
    public var trailingStopLoss: Bool
    /// Stop loss figure associated with this value.
    public var stopLossFigure: Double
    /// Profit factor associated with this value.
    public var profitFactor: Double
    /// Rules associated with this value.
    public var entryRules: [OptimizeRule]
    /// Rules associated with this value.
    public var exitRules: [OptimizeRule]
    /// T1 associated with this value.
    public var t1: Double
    /// T2 associated with this value.
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
    /// Indicator one name associated with this value.
    public var indicatorOneName: String
    /// Indicator one type associated with this value.
    public var indicatorOneType: TechnicalIndicators
    /// Indicator one figure lower associated with this value.
    public var indicatorOneFigureLower: [Double]
    /// Indicator one figure upper associated with this value.
    public var indicatorOneFigureUpper: [Double]
    /// Compare associated with this value.
    public var compare: CompareOption
    /// Indicator two name associated with this value.
    public var indicatorTwoName: String
    /// Indicator two type associated with this value.
    public var indicatorTwoType: TechnicalIndicators
    /// Indicator two figure lower associated with this value.
    public var indicatorTwoFigureLower: [Double]
    /// Indicator two figure upper associated with this value.
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
    /// Rules associated with this value.
    public var rules: [String: [SimulationRule]]

    /// Creates a new instance.
    public init(rules: [String: [SimulationRule]]) {
        self.rules = rules
    }
}

/// Represents `User` in the BacktestingKit public API.
