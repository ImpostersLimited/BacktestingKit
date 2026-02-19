import Foundation

/// Represents `BKV2` in the BacktestingKit public API.
public enum BKV2 {
    /// Represents `Config` in the BacktestingKit public API.
    public struct Config: Codable, Equatable, Hashable {
        public var id: String = UUID().uuidString
        public var transactions: [BKTrade] = []
        public var active: Bool = false
        public var created: Double = 0
        public var instrument: String = ""
        public var last_updated: Double = 0
        public var policyConfig: SimulationPolicyConfig = SimulationPolicyConfig()
        public var analysis: BKAnalysis = BKAnalysis()
        public var status: SimulationStatus = .pending
    }

    /// Represents `OptimizeResult` in the BacktestingKit public API.
    public struct OptimizeResult: Codable, Equatable, Hashable {
        public var id: String = UUID().uuidString
        public var result: [Config] = []
        public var policyConfig: OptimizePolicyConfig = OptimizePolicyConfig()
        public var status: SimulationStatus = .pending
        public var created: Double = 0
        public var last_updated: Double = 0
    }

    /// Represents `Instrument` in the BacktestingKit public API.
    public struct Instrument: Codable, Equatable, Hashable {
        public var pin: Bool
        public var exch: String
        public var exchDisp: String
        public var name: String
        public var type: String
        public var typeDisp: String
        public var id: String = UUID().uuidString
        public var instrument: String = ""
        public var config_history: [Config] = []
        public var optimize_history: [OptimizeResult] = []
        public var last_updated: Double = 0
    }

    /// Represents `FIRUser` in the BacktestingKit public API.
    public struct FIRUser: Codable, Equatable, Hashable {
        public var user_id: String = "TEST_WITH_DEFAULT_USER_ID"
        public var tier: TierSet = .standard
        public var instruments: [String] = []
        public var devices: String = ""
        public var last_updated: Double = 0
        public var id: String = UUID().uuidString
    }

    /// Represents `User` in the BacktestingKit public API.
    public struct User: Codable, Equatable, Hashable {
        public var user_id: String = "TEST_WITH_DEFAULT_USER_ID"
        public var tier: TierSet = .standard
        public var instruments: [Instrument] = []
        public var devices: [Device] = []
        public var last_updated: Double = 0
        public var id: String = UUID().uuidString
    }

    /// Represents `Device` in the BacktestingKit public API.
    public struct Device: Codable, Equatable, Hashable {
        public var id: String = UUID().uuidString
        public var user_id: String = "TEST_WITH_DEFAULT_USER_ID"
        public var device_id: String = ""
        public var device_type: String = ""
        public var last_updated: Double = 0
    }

    /// Represents `BKTrade` in the BacktestingKit public API.
    public struct BKTrade: Codable, Equatable, Hashable {
        public var direction: TradeDirection
        public var entryTime: String
        public var entryPrice: Double
        public var exitTime: String
        public var exitPrice: Double
        public var profit: Double
        public var profitPct: Double
        public var growth: Double
        public var riskPct: Double?
        public var rmultiple: Double?
        public var riskSeries: [BKTimestampedValue]?
        public var holdingPeriod: Double
        public var exitReason: String
        public var stopPrice: Double?
        public var stopPriceSeries: [BKTimestampedValue]?
        public var profitTarget: Double?
    }

    /// Represents `BKTimestampedValue` in the BacktestingKit public API.
    public struct BKTimestampedValue: Codable, Equatable, Hashable {
        public var time: String
        public var value: Double
    }

    /// Represents `BKAnalysis` in the BacktestingKit public API.
    public struct BKAnalysis: Codable, Equatable, Hashable {
        public var startingCapital: Double = 0
        public var finalCapital: Double = 0
        public var profit: Double = 0
        public var profitPct: Double = 0
        public var growth: Double = 0
        public var totalTrades: Double = 0
        public var barCount: Double = 0
        public var maxDrawdown: Double = 0
        public var maxDrawdownPct: Double = 0
        public var maxRiskPct: Double? = 0
        public var expectency: Double? = 0
        public var rmultipleStdDev: Double? = 0
        public var systemQuality: Double? = 0
        public var profitFactor: Double? = 0
        public var proportionProfitable: Double = 0
        public var percentProfitable: Double = 0
        public var returnOnAccount: Double = 0
        public var averageProfitPerTrade: Double = 0
        public var numWinningTrades: Double = 0
        public var numLosingTrades: Double = 0
        public var averageWinningTrade: Double = 0
        public var averageLosingTrade: Double = 0
        public var expectedValue: Double = 0
        public var BKMaxDownDraw: Double = 0
        public var BKMaxDownDrawPct: Double = 0
    }

    /// Represents `SimulationPolicyConfig` in the BacktestingKit public API.
    public struct SimulationPolicyConfig: Codable, Equatable, Hashable {
        public var policy: SimulationPolicy = .custom
        public var trailingStopLoss: Bool = true
        public var stopLossFigure: Double = 15
        public var profitFactor: Double = pow(2, 30)
        public var entryRules: [SimulationRule] = []
        public var exitRules: [SimulationRule] = []
        public var t1: Double = 2
        public var t2: Double = 6
    }

    /// Represents `SimulationRule` in the BacktestingKit public API.
    public struct SimulationRule: Codable, Equatable, Hashable {
        public var indicatorOneName: String = UUID().uuidString.replacing("-", with: "g")
        public var indicatorOneType: TechnicalIndicators = .sma
        public var indicatorOneFigure: [Int] = [15, 0, 0]
        public var compare: CompareOption = .largerOrEqualTo
        public var indicatorTwoName: String = UUID().uuidString.replacing("-", with: "g")
        public var indicatorTwoType: TechnicalIndicators = .close
        public var indicatorTwoFigure: [Int] = [0, 0, 0]
    }

    /// Represents `OptimizePolicyConfig` in the BacktestingKit public API.
    public struct OptimizePolicyConfig: Codable, Equatable, Hashable {
        public var stepSize: Int = 1
        public var simplePolicy: Bool = true
        public var trailingStopLoss: Bool = true
        public var stopLossFigure: Double = 15
        public var profitFactor: Double = pow(2, 30)
        public var entryRules: [OptimizeRule] = []
        public var exitRules: [OptimizeRule] = []
        public var t1: Double = 2
        public var t2: Double = 6
    }

    /// Represents `OptimizeRule` in the BacktestingKit public API.
    public struct OptimizeRule: Codable, Equatable, Hashable {
        public var indicatorOneName: String = UUID().uuidString.replacing("-", with: "g")
        public var indicatorOneType: TechnicalIndicators = .sma
        public var indicatorOneFigureLower: [Int] = [3, 0, 0]
        public var indicatorOneFigureUpper: [Int] = [150, 0, 0]
        public var compare: CompareOption = .largerOrEqualTo
        public var indicatorTwoName: String = UUID().uuidString.replacing("-", with: "g")
        public var indicatorTwoType: TechnicalIndicators = .close
        public var indicatorTwoFigureLower: [Int] = [0, 0, 0]
        public var indicatorTwoFigureUpper: [Int] = [0, 0, 0]
    }

    /// Represents `DynamodbTrigger` in the BacktestingKit public API.
    public struct DynamodbTrigger: Codable, Equatable, Hashable {
        public var uuid: String = UUID().uuidString
        public var type: TriggerType
        public var itemId: String
        public var optimize: [OptimizePolicyConfig]
        public var simulate: [SimulationPolicyConfig]
        public var instrument: String
        public var user_id: String
    }

    /// Represents `SimulateConfigOutput` in the BacktestingKit public API.
    public struct SimulateConfigOutput: Codable, Hashable {
        public var analysis: BKAnalysis
        public var trades: [BKTrade]
        public var config: SimulationPolicyConfig
    }

    /// Represents `OptimizeConfigOutput` in the BacktestingKit public API.
    public struct OptimizeConfigOutput: Codable, Hashable {
        public var analysis: BKAnalysis
        public var trades: [BKTrade]
        public var config: SimulationPolicyConfig
    }

    /// Represents `TriggerType` in the BacktestingKit public API.
    public enum TriggerType: String, Codable, CaseIterable, Hashable {
        case optimize
        case simulate
    }

    /// Represents `SimulationStatus` in the BacktestingKit public API.
    public enum SimulationStatus: String, Codable, CaseIterable, Hashable {
        case pending
        case simulating
        case finished
        case failed
    }

    /// Represents `SimulationTimeframe` in the BacktestingKit public API.
    public enum SimulationTimeframe: Double, Codable, CaseIterable, Hashable {
        case sixMonths = 0.0
        case oneYear = 1.0
        case twoYears = 2.0
        case threeYears = 3.0
        case fourYears = 4.0
        case fiveYears = 5.0
        case present = 6.0
    }

    /// Represents `TradeDirection` in the BacktestingKit public API.
    public enum TradeDirection: String, Codable, CaseIterable, Hashable {
        case long = "long"
        case short = "short"
    }

    /// Represents `TechnicalIndicators` in the BacktestingKit public API.
    public enum TechnicalIndicators: String, Codable, CaseIterable, Hashable {
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

    /// Represents `CompareOption` in the BacktestingKit public API.
    public enum CompareOption: String, Codable, CaseIterable, Hashable {
        case largerOrEqualTo
        case largerThan
        case equalTo
        case smallThan
        case smallerOrEqualTo
    }

    /// Represents `SimulationPolicy` in the BacktestingKit public API.
    public enum SimulationPolicy: String, Codable, CaseIterable, Hashable {
        case sma
        case ema
        case macd
        case stochasticSlow
        case stochasticFast
        case bollinger
        case custom = "CUSTOM_STRATEGY"
        case macdWithSma = "macdSma"
        case macdWithEma = "macdEma"
        case smaCrossover
        case emaCrossover
        case smaMeanReversion
        case emaMeanReversion
    }

    /// Represents `PresetStrategy` in the BacktestingKit public API.
    public enum PresetStrategy: String, Codable, Hashable, CaseIterable {
        case macd = "MACD"
        case sma = "Simple SMA Strategy"
        case ema = "Simple EMA Strategy"
        case macdWithSma = "Simple SMA with MACD Strategy"
        case macdWithEma = "Simple EMA with MACD Strategy"
        case bollinger = "Bollinger Bands"
        case stochasticSlow = "Slow Stochastic Strategy"
        case stochasticFast = "Fast Stochastic Strategy"
        case smaCrossover = "Basic SMA Crossover"
        case emaCrossover = "Basic EMA Crossover"
        case smaMeanReversion = "Mean Reversion with SMA"
        case emaMeanReversion = "Mean Reversion with EMA"
    }
}
