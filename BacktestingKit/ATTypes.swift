import Foundation

public enum ATEntitlement: String, Codable {
    case pro
    case standard
}

public enum TierSet: String, Codable {
    case pro
    case standard
}

public enum ATMinMax: String, Codable {
    case min
    case max
}

public enum CompareOption: String, Codable {
    case largerOrEqualTo
    case largerThan
    case equalTo
    case smallThan
    case smallerOrEqualTo
}

public enum SimulationPolicy: String, Codable {
    case sma
    case ema
    case macd
    case stochasticSlow
    case stochasticFast
    case bollinger
    case macdSma
    case macdEma
    case smaCrossover
    case emaCrossover
    case smaMeanReversion
    case emaMeanReversion
    case customStrategy = "CUSTOM_STRATEGY"
}

public enum TechnicalIndicators: String, Codable {
    case sma
    case macd
    case ema
    case bollingerUpper
    case bollingerLower
    case bollingerMiddle
    case rsi
    case stochasticSlowPercentD
    case stochasticSlowPercentK
    case stochasticFastPercentD
    case stochasticFastPercentK
    case close
    case constant
}

public enum SimulationStatus: String, Codable {
    case pending
    case simulating
    case finished
    case failed
}

public struct ATAnalysis: Codable, Equatable {
    public var ATMaxDownDraw: Double
    public var ATMaxDownDrawPct: Double
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

    public init(
        ATMaxDownDraw: Double = 0,
        ATMaxDownDrawPct: Double = 0,
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
        self.ATMaxDownDraw = ATMaxDownDraw
        self.ATMaxDownDrawPct = ATMaxDownDrawPct
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

public struct ATTimestampedValue: Codable, Equatable {
    public var time: Date
    public var value: Double

    public init(time: Date, value: Double) {
        self.time = time
        self.value = value
    }
}

public struct ATTrade: Codable, Equatable {
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
    public var riskSeries: [ATTimestampedValue]
    public var holdingPeriod: Int
    public var exitReason: String
    public var stopPrice: Double
    public var stopPriceSeries: [ATTimestampedValue]
    public var profitTarget: Double

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
        riskSeries: [ATTimestampedValue] = [],
        holdingPeriod: Int,
        exitReason: String,
        stopPrice: Double = 0,
        stopPriceSeries: [ATTimestampedValue] = [],
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

public struct SimulationRule: Codable, Equatable {
    public var indicatorOneName: String
    public var indicatorOneType: TechnicalIndicators
    public var indicatorOneFigure: [Double]
    public var compare: CompareOption
    public var indicatorTwoName: String
    public var indicatorTwoType: TechnicalIndicators
    public var indicatorTwoFigure: [Double]

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

public struct SimulationPolicyConfig: Codable, Equatable {
    public var policy: SimulationPolicy
    public var trailingStopLoss: Bool
    public var stopLossFigure: Double
    public var profitFactor: Double
    public var entryRules: [SimulationRule]
    public var exitRules: [SimulationRule]
    public var t1: Double
    public var t2: Double

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

public struct OptimizeRulesContainer: Codable, Equatable {
    public var rules: [String: [SimulationRule]]

    public init(rules: [String: [SimulationRule]]) {
        self.rules = rules
    }
}

public struct User: Codable, Equatable {
    public var devices: [Device]
    public var id: String
    public var instruments: [Instrument]
    public var user_id: String
    public var tier: ATEntitlement
    public var last_updated: Double
}

public struct Device: Codable, Equatable {
    public var device_id: String
    public var device_type: String
    public var id: String
    public var last_updated: Double
    public var user_id: String
}

public struct Instrument: Codable, Equatable {
    public var pin: Bool
    public var exch: String
    public var exchDisp: String
    public var name: String
    public var type: String
    public var typeDisp: String
    public var config_history: [Config]
    public var optimize_history: [OptimizeResult]
    public var id: String
    public var instrument: String
    public var last_updated: Double
}

public struct Config: Codable, Equatable {
    public var id: String
    public var transactions: [ATTrade]
    public var active: Bool
    public var created: Double
    public var instrument: String
    public var last_updated: Double
    public var policyConfig: SimulationPolicyConfig
    public var analysis: ATAnalysis
    public var status: SimulationStatus
}

public struct OptimizeResult: Codable, Equatable {
    public var id: String
    public var result: [Config]
    public var policyConfig: OptimizePolicyConfig
    public var last_updated: Double
    public var created: Double
    public var status: SimulationStatus
}

public enum TriggerType: String, Codable {
    case optimize
    case simulate
}

public struct DynamodbTrigger: Codable, Equatable {
    public var uuid: String
    public var type: TriggerType
    public var itemId: String
    public var optimize: [OptimizePolicyConfig]
    public var simulate: [SimulationPolicyConfig]
    public var instrument: String
    public var user_id: String
}

public enum SimulationTimeframe: Double, Codable {
    case t0 = 0.0
    case t1 = 1.0
    case t2 = 2.0
    case t3 = 3.0
    case t4 = 4.0
    case t5 = 5.0
    case t6 = 6.0
}

public func ATAnalysisTypeCheck(_ input: ATAnalysis) -> ATAnalysis {
    var result = input
    if result.maxRiskPct == nil { result.maxRiskPct = 0 }
    if result.systemQuality == nil { result.systemQuality = 0 }
    return result
}
