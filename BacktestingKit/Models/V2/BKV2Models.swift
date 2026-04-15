import Foundation

/// Represents `BKV2` in the BacktestingKit public API.
public enum BKV2 {
    /// Represents `Config` in the BacktestingKit public API.
    public struct Config: Codable, Equatable, Hashable {
        /// Stable identifier for this value.
        public var id: String = UUID().uuidString
        /// Transactions associated with this value.
        public var transactions: [BKTrade] = []
        /// Active associated with this value.
        public var active: Bool = false
        /// Created associated with this value.
        public var created: Double = 0
        /// Instrument associated with this value.
        public var instrument: String = ""
        /// Last updated associated with this value.
        public var last_updated: Double = 0
        /// Configuration associated with this value.
        public var policyConfig: SimulationPolicyConfig = SimulationPolicyConfig()
        /// Analysis associated with this value.
        public var analysis: BKAnalysis = BKAnalysis()
        /// Current status associated with this value.
        public var status: SimulationStatus = .pending
    }

    /// Represents `OptimizeResult` in the BacktestingKit public API.
    public struct OptimizeResult: Codable, Equatable, Hashable {
        /// Stable identifier for this value.
        public var id: String = UUID().uuidString
        /// Result associated with this value.
        public var result: [Config] = []
        /// Configuration associated with this value.
        public var policyConfig: OptimizePolicyConfig = OptimizePolicyConfig()
        /// Current status associated with this value.
        public var status: SimulationStatus = .pending
        /// Created associated with this value.
        public var created: Double = 0
        /// Last updated associated with this value.
        public var last_updated: Double = 0
    }

    /// Represents `Instrument` in the BacktestingKit public API.
    public struct Instrument: Codable, Equatable, Hashable {
        /// Pin associated with this value.
        public var pin: Bool
        /// Exch associated with this value.
        public var exch: String
        /// Exch disp associated with this value.
        public var exchDisp: String
        /// Name associated with this value.
        public var name: String
        /// Type associated with this value.
        public var type: String
        /// Type disp associated with this value.
        public var typeDisp: String
        /// Stable identifier for this value.
        public var id: String = UUID().uuidString
        /// Instrument associated with this value.
        public var instrument: String = ""
        /// Configuration associated with this value.
        public var config_history: [Config] = []
        /// Optimize history associated with this value.
        public var optimize_history: [OptimizeResult] = []
        /// Last updated associated with this value.
        public var last_updated: Double = 0
    }

    /// Represents `FIRUser` in the BacktestingKit public API.
    public struct FIRUser: Codable, Equatable, Hashable {
        /// Identifier associated with this value.
        public var user_id: String = "TEST_WITH_DEFAULT_USER_ID"
        /// Tier associated with this value.
        public var tier: TierSet = .standard
        /// Instruments associated with this value.
        public var instruments: [String] = []
        /// Devices associated with this value.
        public var devices: String = ""
        /// Last updated associated with this value.
        public var last_updated: Double = 0
        /// Stable identifier for this value.
        public var id: String = UUID().uuidString
    }

    /// Represents `User` in the BacktestingKit public API.
    public struct User: Codable, Equatable, Hashable {
        /// Identifier associated with this value.
        public var user_id: String = "TEST_WITH_DEFAULT_USER_ID"
        /// Tier associated with this value.
        public var tier: TierSet = .standard
        /// Instruments associated with this value.
        public var instruments: [Instrument] = []
        /// Devices associated with this value.
        public var devices: [Device] = []
        /// Last updated associated with this value.
        public var last_updated: Double = 0
        /// Stable identifier for this value.
        public var id: String = UUID().uuidString
    }

    /// Represents `Device` in the BacktestingKit public API.
    public struct Device: Codable, Equatable, Hashable {
        /// Stable identifier for this value.
        public var id: String = UUID().uuidString
        /// Identifier associated with this value.
        public var user_id: String = "TEST_WITH_DEFAULT_USER_ID"
        /// Identifier associated with this value.
        public var device_id: String = ""
        /// Device type associated with this value.
        public var device_type: String = ""
        /// Last updated associated with this value.
        public var last_updated: Double = 0
    }

    /// Represents `BKTrade` in the BacktestingKit public API.
    public struct BKTrade: Codable, Equatable, Hashable {
        /// Direction associated with this value.
        public var direction: TradeDirection
        /// Entry time associated with this value.
        public var entryTime: String
        /// Entry price associated with this value.
        public var entryPrice: Double
        /// Exit time associated with this value.
        public var exitTime: String
        /// Exit price associated with this value.
        public var exitPrice: Double
        /// Profit associated with this value.
        public var profit: Double
        /// Profit percentage associated with this value.
        public var profitPct: Double
        /// Growth associated with this value.
        public var growth: Double
        /// Risk percentage associated with this value.
        public var riskPct: Double?
        /// Rmultiple associated with this value.
        public var rmultiple: Double?
        /// Risk series associated with this value.
        public var riskSeries: [BKTimestampedValue]?
        /// Holding period associated with this value.
        public var holdingPeriod: Double
        /// Exit reason associated with this value.
        public var exitReason: String
        /// Stop price associated with this value.
        public var stopPrice: Double?
        /// Stop price series associated with this value.
        public var stopPriceSeries: [BKTimestampedValue]?
        /// Profit target associated with this value.
        public var profitTarget: Double?
    }

    /// Represents `BKTimestampedValue` in the BacktestingKit public API.
    public struct BKTimestampedValue: Codable, Equatable, Hashable {
        /// Timestamp associated with this value.
        public var time: String
        /// Value associated with this value.
        public var value: Double
    }

    /// Represents `BKAnalysis` in the BacktestingKit public API.
    public struct BKAnalysis: Codable, Equatable, Hashable {
        /// Starting capital associated with this value.
        public var startingCapital: Double = 0
        /// Final capital associated with this value.
        public var finalCapital: Double = 0
        /// Profit associated with this value.
        public var profit: Double = 0
        /// Profit percentage associated with this value.
        public var profitPct: Double = 0
        /// Growth associated with this value.
        public var growth: Double = 0
        /// Total trades represented by this value.
        public var totalTrades: Double = 0
        /// Number of bars represented by this value.
        public var barCount: Double = 0
        /// Maximum drawdown associated with this value.
        public var maxDrawdown: Double = 0
        /// Maximum drawdown percentage associated with this value.
        public var maxDrawdownPct: Double = 0
        /// Maximum risk percentage associated with this value.
        public var maxRiskPct: Double? = 0
        /// Expectency associated with this value.
        public var expectency: Double? = 0
        /// Rmultiple standard deviation associated with this value.
        public var rmultipleStdDev: Double? = 0
        /// System quality associated with this value.
        public var systemQuality: Double? = 0
        /// Profit factor associated with this value.
        public var profitFactor: Double? = 0
        /// Proportion profitable associated with this value.
        public var proportionProfitable: Double = 0
        /// Percent profitable associated with this value.
        public var percentProfitable: Double = 0
        /// Return on account represented by this value.
        public var returnOnAccount: Double = 0
        /// Average profit per trade associated with this value.
        public var averageProfitPerTrade: Double = 0
        /// Number winning trades represented by this value.
        public var numWinningTrades: Double = 0
        /// Number losing trades represented by this value.
        public var numLosingTrades: Double = 0
        /// Average winning trade associated with this value.
        public var averageWinningTrade: Double = 0
        /// Average losing trade associated with this value.
        public var averageLosingTrade: Double = 0
        /// Expected value associated with this value.
        public var expectedValue: Double = 0
        /// Backtest maximum down draw associated with this value.
        public var BKMaxDownDraw: Double = 0
        /// Backtest maximum down draw percentage associated with this value.
        public var BKMaxDownDrawPct: Double = 0
    }

    /// Represents `SimulationPolicyConfig` in the BacktestingKit public API.
    public struct SimulationPolicyConfig: Codable, Equatable, Hashable {
        /// Policy associated with this value.
        public var policy: SimulationPolicy = .custom
        /// Trailing stop loss associated with this value.
        public var trailingStopLoss: Bool = true
        /// Stop loss figure associated with this value.
        public var stopLossFigure: Double = 15
        /// Profit factor associated with this value.
        public var profitFactor: Double = pow(2, 30)
        /// Rules associated with this value.
        public var entryRules: [SimulationRule] = []
        /// Rules associated with this value.
        public var exitRules: [SimulationRule] = []
        /// T1 associated with this value.
        public var t1: Double = 2
        /// T2 associated with this value.
        public var t2: Double = 6
    }

    /// Represents `SimulationRule` in the BacktestingKit public API.
    public struct SimulationRule: Codable, Equatable, Hashable {
        /// Indicator one name associated with this value.
        public var indicatorOneName: String = UUID().uuidString.replacing("-", with: "g")
        /// Indicator one type associated with this value.
        public var indicatorOneType: TechnicalIndicators = .sma
        /// Indicator one figure associated with this value.
        public var indicatorOneFigure: [Int] = [15, 0, 0]
        /// Compare associated with this value.
        public var compare: CompareOption = .largerOrEqualTo
        /// Indicator two name associated with this value.
        public var indicatorTwoName: String = UUID().uuidString.replacing("-", with: "g")
        /// Indicator two type associated with this value.
        public var indicatorTwoType: TechnicalIndicators = .close
        /// Indicator two figure associated with this value.
        public var indicatorTwoFigure: [Int] = [0, 0, 0]
    }

    /// Represents `OptimizePolicyConfig` in the BacktestingKit public API.
    public struct OptimizePolicyConfig: Codable, Equatable, Hashable {
        /// Step size associated with this value.
        public var stepSize: Int = 1
        /// Simple policy associated with this value.
        public var simplePolicy: Bool = true
        /// Trailing stop loss associated with this value.
        public var trailingStopLoss: Bool = true
        /// Stop loss figure associated with this value.
        public var stopLossFigure: Double = 15
        /// Profit factor associated with this value.
        public var profitFactor: Double = pow(2, 30)
        /// Rules associated with this value.
        public var entryRules: [OptimizeRule] = []
        /// Rules associated with this value.
        public var exitRules: [OptimizeRule] = []
        /// T1 associated with this value.
        public var t1: Double = 2
        /// T2 associated with this value.
        public var t2: Double = 6
    }

    /// Represents `OptimizeRule` in the BacktestingKit public API.
    public struct OptimizeRule: Codable, Equatable, Hashable {
        /// Indicator one name associated with this value.
        public var indicatorOneName: String = UUID().uuidString.replacing("-", with: "g")
        /// Indicator one type associated with this value.
        public var indicatorOneType: TechnicalIndicators = .sma
        /// Indicator one figure lower associated with this value.
        public var indicatorOneFigureLower: [Int] = [3, 0, 0]
        /// Indicator one figure upper associated with this value.
        public var indicatorOneFigureUpper: [Int] = [150, 0, 0]
        /// Compare associated with this value.
        public var compare: CompareOption = .largerOrEqualTo
        /// Indicator two name associated with this value.
        public var indicatorTwoName: String = UUID().uuidString.replacing("-", with: "g")
        /// Indicator two type associated with this value.
        public var indicatorTwoType: TechnicalIndicators = .close
        /// Indicator two figure lower associated with this value.
        public var indicatorTwoFigureLower: [Int] = [0, 0, 0]
        /// Indicator two figure upper associated with this value.
        public var indicatorTwoFigureUpper: [Int] = [0, 0, 0]
    }

    /// Represents `DynamodbTrigger` in the BacktestingKit public API.
    public struct DynamodbTrigger: Codable, Equatable, Hashable {
        /// Stable identifier for this value.
        public var uuid: String = UUID().uuidString
        /// Type associated with this value.
        public var type: TriggerType
        /// Item ID associated with this value.
        public var itemId: String
        /// Optimize associated with this value.
        public var optimize: [OptimizePolicyConfig]
        /// Simulate associated with this value.
        public var simulate: [SimulationPolicyConfig]
        /// Instrument associated with this value.
        public var instrument: String
        /// Identifier associated with this value.
        public var user_id: String
    }

    /// Represents `SimulateConfigOutput` in the BacktestingKit public API.
    public struct SimulateConfigOutput: Codable, Hashable {
        /// Analysis associated with this value.
        public var analysis: BKAnalysis
        /// Trades associated with this value.
        public var trades: [BKTrade]
        /// Configuration associated with this value.
        public var config: SimulationPolicyConfig
    }

    /// Represents `OptimizeConfigOutput` in the BacktestingKit public API.
    public struct OptimizeConfigOutput: Codable, Hashable {
        /// Analysis associated with this value.
        public var analysis: BKAnalysis
        /// Trades associated with this value.
        public var trades: [BKTrade]
        /// Configuration associated with this value.
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
