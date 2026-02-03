import Foundation

public enum ATV2 {
    public struct Config: Codable, Equatable, Hashable {
        public var id: String = UUID().uuidString
        public var transactions: [ATTrade] = []
        public var active: Bool = false
        public var created: Double = 0
        public var instrument: String = ""
        public var last_updated: Double = 0
        public var policyConfig: SimulationPolicyConfig = SimulationPolicyConfig()
        public var analysis: ATAnalysis = ATAnalysis()
        public var status: SimulationStatus = .pending
    }

    public struct OptimizeResult: Codable, Equatable, Hashable {
        public var id: String = UUID().uuidString
        public var result: [Config] = []
        public var policyConfig: OptimizePolicyConfig = OptimizePolicyConfig()
        public var status: SimulationStatus = .pending
        public var created: Double = 0
        public var last_updated: Double = 0
    }

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

    public struct FIRUser: Codable, Equatable, Hashable {
        public var user_id: String = "TEST_WITH_DEFAULT_USER_ID"
        public var tier: TierSet = .standard
        public var instruments: [String] = []
        public var devices: String = ""
        public var last_updated: Double = 0
        public var id: String = UUID().uuidString
    }

    public struct User: Codable, Equatable, Hashable {
        public var user_id: String = "TEST_WITH_DEFAULT_USER_ID"
        public var tier: TierSet = .standard
        public var instruments: [Instrument] = []
        public var devices: [Device] = []
        public var last_updated: Double = 0
        public var id: String = UUID().uuidString
    }

    public struct Device: Codable, Equatable, Hashable {
        public var id: String = UUID().uuidString
        public var user_id: String = "TEST_WITH_DEFAULT_USER_ID"
        public var device_id: String = ""
        public var device_type: String = ""
        public var last_updated: Double = 0
    }

    public struct ATTrade: Codable, Equatable, Hashable {
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
        public var riskSeries: [ATTimestampedValue]?
        public var holdingPeriod: Double
        public var exitReason: String
        public var stopPrice: Double?
        public var stopPriceSeries: [ATTimestampedValue]?
        public var profitTarget: Double?
    }

    public struct ATTimestampedValue: Codable, Equatable, Hashable {
        public var time: String
        public var value: Double
    }

    public struct ATAnalysis: Codable, Equatable, Hashable {
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
        public var ATMaxDownDraw: Double = 0
        public var ATMaxDownDrawPct: Double = 0
    }

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

    public struct SimulationRule: Codable, Equatable, Hashable {
        public var indicatorOneName: String = UUID().uuidString.replacingOccurrences(of: "-", with: "g")
        public var indicatorOneType: TechnicalIndicators = .sma
        public var indicatorOneFigure: [Int] = [15, 0, 0]
        public var compare: CompareOption = .largerOrEqualTo
        public var indicatorTwoName: String = UUID().uuidString.replacingOccurrences(of: "-", with: "g")
        public var indicatorTwoType: TechnicalIndicators = .close
        public var indicatorTwoFigure: [Int] = [0, 0, 0]
    }

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

    public struct OptimizeRule: Codable, Equatable, Hashable {
        public var indicatorOneName: String = UUID().uuidString.replacingOccurrences(of: "-", with: "g")
        public var indicatorOneType: TechnicalIndicators = .sma
        public var indicatorOneFigureLower: [Int] = [3, 0, 0]
        public var indicatorOneFigureUpper: [Int] = [150, 0, 0]
        public var compare: CompareOption = .largerOrEqualTo
        public var indicatorTwoName: String = UUID().uuidString.replacingOccurrences(of: "-", with: "g")
        public var indicatorTwoType: TechnicalIndicators = .close
        public var indicatorTwoFigureLower: [Int] = [0, 0, 0]
        public var indicatorTwoFigureUpper: [Int] = [0, 0, 0]
    }

    public struct DynamodbTrigger: Codable, Equatable, Hashable {
        public var uuid: String = UUID().uuidString
        public var type: TriggerType
        public var itemId: String
        public var optimize: [OptimizePolicyConfig]
        public var simulate: [SimulationPolicyConfig]
        public var instrument: String
        public var user_id: String
    }

    public struct SimulateConfigOutput: Codable, Hashable {
        public var analysis: ATAnalysis
        public var trades: [ATTrade]
        public var config: SimulationPolicyConfig
    }

    public struct OptimizeConfigOutput: Codable, Hashable {
        public var analysis: ATAnalysis
        public var trades: [ATTrade]
        public var config: SimulationPolicyConfig
    }

    public enum TriggerType: String, Codable, CaseIterable, Hashable {
        case optimize
        case simulate
    }

    public enum SimulationStatus: String, Codable, CaseIterable, Hashable {
        case pending
        case simulating
        case finished
        case failed
    }

    public enum SimulationTimeframe: Double, Codable, CaseIterable, Hashable {
        case sixMonths = 0.0
        case oneYear = 1.0
        case twoYears = 2.0
        case threeYears = 3.0
        case fourYears = 4.0
        case fiveYears = 5.0
        case present = 6.0
    }

    public enum TradeDirection: String, Codable, CaseIterable, Hashable {
        case long = "long"
        case short = "short"
    }

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

    public enum CompareOption: String, Codable, CaseIterable, Hashable {
        case largerOrEqualTo
        case largerThan
        case equalTo
        case smallThan
        case smallerOrEqualTo
    }

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

