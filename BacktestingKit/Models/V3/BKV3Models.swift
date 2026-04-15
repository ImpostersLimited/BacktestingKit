import Foundation

/// Represents `BKV3_AnalysisProfile` in the BacktestingKit public API.
public struct BKV3_AnalysisProfile: Codable, Equatable {
    /// Stable identifier for this value.
    public var id: String
    /// Starting capital associated with this value.
    public var startingCapital: Double?
    /// Final capital associated with this value.
    public var finalCapital: Double?
    /// Profit associated with this value.
    public var profit: Double?
    /// Profit percentage associated with this value.
    public var profitPct: Double?
    /// Growth associated with this value.
    public var growth: Double?
    /// Total trades represented by this value.
    public var totalTrades: Double?
    /// Number of bars represented by this value.
    public var barCount: Double?
    /// Maximum drawdown associated with this value.
    public var maxDrawdown: Double?
    /// Maximum drawdown percentage associated with this value.
    public var maxDrawdownPct: Double?
    /// Maximum risk percentage associated with this value.
    public var maxRiskPct: Double?
    /// Expectency associated with this value.
    public var expectency: Double?
    /// Rmultiple standard deviation associated with this value.
    public var rmultipleStdDev: Double?
    /// System quality associated with this value.
    public var systemQuality: Double?
    /// Profit factor associated with this value.
    public var profitFactor: Double?
    /// Proportion profitable associated with this value.
    public var proportionProfitable: Double?
    /// Percent profitable associated with this value.
    public var percentProfitable: Double?
    /// Return on account represented by this value.
    public var returnOnAccount: Double?
    /// Average profit per trade associated with this value.
    public var averageProfitPerTrade: Double?
    /// Number winning trades represented by this value.
    public var numWinningTrades: Double?
    /// Number losing trades represented by this value.
    public var numLosingTrades: Double?
    /// Average winning trade associated with this value.
    public var averageWinningTrade: Double?
    /// Average losing trade associated with this value.
    public var averageLosingTrade: Double?
    /// Expected value associated with this value.
    public var expectedValue: Double?
    /// Maximum down draw new associated with this value.
    public var maxDownDrawNew: Double?
    /// Maximum down draw percentage new associated with this value.
    public var maxDownDrawPctNew: Double?
    /// Created at associated with this value.
    public var createdAt: Date?
    /// Last updated associated with this value.
    public var lastUpdated: Date?
    /// Configuration associated with this value.
    public var configId: String?
    /// Instrument ID associated with this value.
    public var instrumentId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case startingCapital = "starting_capital"
        case finalCapital = "final_capital"
        case profit
        case profitPct = "profit_pct"
        case growth
        case totalTrades = "total_trades"
        case barCount = "bar_count"
        case maxDrawdown = "max_drawdown"
        case maxDrawdownPct = "max_drawdown_pct"
        case maxRiskPct = "max_risk_pct"
        case expectency
        case rmultipleStdDev = "rmultiple_std_dev"
        case systemQuality = "system_quality"
        case profitFactor = "profit_factor"
        case proportionProfitable = "proportion_profitable"
        case percentProfitable = "percent_profitable"
        case returnOnAccount = "return_on_account"
        case averageProfitPerTrade = "average_profit_per_trade"
        case numWinningTrades = "num_winning_trades"
        case numLosingTrades = "num_losing_trades"
        case averageWinningTrade = "average_winning_trade"
        case averageLosingTrade = "average_losing_trade"
        case expectedValue = "expected_value"
        case maxDownDrawNew = "max_down_draw_new"
        case maxDownDrawPctNew = "max_down_draw_pct_new"
        case createdAt = "created_at"
        case lastUpdated = "last_updated"
        case configId = "config_id"
        case instrumentId = "instrument_id"
    }
}

/// Represents `BKV3_Config` in the BacktestingKit public API.
public struct BKV3_Config: Codable, Equatable {
    /// Stable identifier for this value.
    public var id: String
    /// Active associated with this value.
    public var active: Bool?
    /// Created at associated with this value.
    public var createdAt: Date?
    /// Instrument ID associated with this value.
    public var instrumentId: String?
    /// Last updated associated with this value.
    public var lastUpdated: Date?
    /// Current status associated with this value.
    public var status: String?
    /// Optimize result ID associated with this value.
    public var optimizeResultId: String?
    /// Policy associated with this value.
    public var policy: SimulationPolicy?
    /// Last status associated with this value.
    public var lastStatus: PositionStatus?
    /// Trailing stop loss associated with this value.
    public var trailingStopLoss: Bool?
    /// Stop loss figure associated with this value.
    public var stopLossFigure: Double?
    /// Profit factor associated with this value.
    public var profitFactor: Double?
    /// T1 associated with this value.
    public var t1: Double?
    /// T2 associated with this value.
    public var t2: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case active
        case createdAt = "created_at"
        case instrumentId = "instrument_id"
        case lastUpdated = "last_updated"
        case status
        case optimizeResultId = "optimize_result_id"
        case policy
        case lastStatus = "last_status"
        case trailingStopLoss = "trailing_stop_loss"
        case stopLossFigure = "stop_loss_figure"
        case profitFactor = "profit_factor"
        case t1
        case t2
    }
}

/// Represents `BKV3_InstrumentInfo` in the BacktestingKit public API.
public struct BKV3_InstrumentInfo: Codable, Equatable {
    /// Stable identifier for this value.
    public var id: String
    /// Name associated with this value.
    public var name: String?
    /// Exchange code associated with this value.
    public var exchange: String?
    /// Quote type associated with this value.
    public var quoteType: String?
    /// Created at associated with this value.
    public var createdAt: Date?
    /// Last updated associated with this value.
    public var lastUpdated: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case exchange
        case name
        case quoteType = "quote_type"
        case createdAt = "created_at"
        case lastUpdated = "last_updated"
    }
}

/// Represents `BKV3_OptimizePolicyConfig` in the BacktestingKit public API.
public struct BKV3_OptimizePolicyConfig: Codable, Equatable {
    /// Stable identifier for this value.
    public var id: String
    /// Step size associated with this value.
    public var stepSize: Int?
    /// Simple policy associated with this value.
    public var simplePolicy: Bool?
    /// Trailing stop loss associated with this value.
    public var trailingStopLoss: Bool?
    /// Stop loss figure associated with this value.
    public var stopLossFigure: Double?
    /// Profit factor associated with this value.
    public var profitFactor: Double?
    /// T1 associated with this value.
    public var t1: Double?
    /// T2 associated with this value.
    public var t2: Double?
    /// Created at associated with this value.
    public var createdAt: Date?
    /// Last updated associated with this value.
    public var lastUpdated: Date?
    /// Optimize result ID associated with this value.
    public var optimizeResultId: String?
    /// Instrument ID associated with this value.
    public var instrumentId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case stepSize = "step_size"
        case simplePolicy = "simple_policy"
        case trailingStopLoss = "trailing_stop_loss"
        case stopLossFigure = "stop_loss_figure"
        case profitFactor = "profit_factor"
        case t1
        case t2
        case createdAt = "created_at"
        case lastUpdated = "last_updated"
        case optimizeResultId = "optimize_result_id"
        case instrumentId = "instrument_id"
    }
}

/// Represents `BKV3_OptimizeResult` in the BacktestingKit public API.
public struct BKV3_OptimizeResult: Codable, Equatable {
    /// Stable identifier for this value.
    public var id: String
    /// Current status associated with this value.
    public var status: String?
    /// Created at associated with this value.
    public var createdAt: Date?
    /// Last updated associated with this value.
    public var lastUpdated: Date?
    /// Instrument ID associated with this value.
    public var instrumentId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case createdAt = "created_at"
        case lastUpdated = "last_updated"
        case instrumentId = "instrument_id"
    }
}

/// Represents `BKV3_OptimizeRule` in the BacktestingKit public API.
public struct BKV3_OptimizeRule: Codable, Equatable {
    /// Stable identifier for this value.
    public var id: String
    /// Indicator one name associated with this value.
    public var indicatorOneName: String?
    /// Indicator one type associated with this value.
    public var indicatorOneType: String?
    /// Indicator one figure lower one associated with this value.
    public var indicatorOneFigureLowerOne: Double?
    /// Indicator one figure lower two associated with this value.
    public var indicatorOneFigureLowerTwo: Double?
    /// Indicator one figure lower three associated with this value.
    public var indicatorOneFigureLowerThree: Double?
    /// Indicator one figure upper one associated with this value.
    public var indicatorOneFigureUpperOne: Double?
    /// Indicator one figure upper two associated with this value.
    public var indicatorOneFigureUpperTwo: Double?
    /// Indicator one figure upper three associated with this value.
    public var indicatorOneFigureUpperThree: Double?
    /// Compare associated with this value.
    public var compare: String?
    /// Indicator two name associated with this value.
    public var indicatorTwoName: String?
    /// Indicator two type associated with this value.
    public var indicatorTwoType: String?
    /// Indicator two figure lower one associated with this value.
    public var indicatorTwoFigureLowerOne: Double?
    /// Indicator two figure lower two associated with this value.
    public var indicatorTwoFigureLowerTwo: Double?
    /// Indicator two figure lower three associated with this value.
    public var indicatorTwoFigureLowerThree: Double?
    /// Indicator two figure upper one associated with this value.
    public var indicatorTwoFigureUpperOne: Double?
    /// Indicator two figure upper two associated with this value.
    public var indicatorTwoFigureUpperTwo: Double?
    /// Indicator two figure upper three associated with this value.
    public var indicatorTwoFigureUpperThree: Double?
    /// Created at associated with this value.
    public var createdAt: Date?
    /// Last updated associated with this value.
    public var lastUpdated: Date?
    /// Configuration associated with this value.
    public var optimizePolicyConfigId: String?
    /// Rule type associated with this value.
    public var ruleType: RuleType?
    /// Instrument ID associated with this value.
    public var instrumentId: String?
    /// Optimize result ID associated with this value.
    public var optimizeResultId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case indicatorOneName = "indicator_one_name"
        case indicatorOneType = "indicator_one_type"
        case indicatorOneFigureLowerOne = "indicator_one_figure_lower_one"
        case indicatorOneFigureLowerTwo = "indicator_one_figure_lower_two"
        case indicatorOneFigureLowerThree = "indicator_one_figure_lower_three"
        case indicatorOneFigureUpperOne = "indicator_one_figure_upper_one"
        case indicatorOneFigureUpperTwo = "indicator_one_figure_upper_two"
        case indicatorOneFigureUpperThree = "indicator_one_figure_upper_three"
        case compare
        case indicatorTwoName = "indicator_two_name"
        case indicatorTwoType = "indicator_two_type"
        case indicatorTwoFigureLowerOne = "indicator_two_figure_lower_one"
        case indicatorTwoFigureLowerTwo = "indicator_two_figure_lower_two"
        case indicatorTwoFigureLowerThree = "indicator_two_figure_lower_three"
        case indicatorTwoFigureUpperOne = "indicator_two_figure_upper_one"
        case indicatorTwoFigureUpperTwo = "indicator_two_figure_upper_two"
        case indicatorTwoFigureUpperThree = "indicator_two_figure_upper_three"
        case createdAt = "created_at"
        case lastUpdated = "last_updated"
        case optimizePolicyConfigId = "optimize_policy_config_id"
        case ruleType = "rule_type"
        case instrumentId = "instrument_id"
        case optimizeResultId = "optimize_result_id"
    }
}

/// Represents `BKV3_RiskProfile` in the BacktestingKit public API.
public struct BKV3_RiskProfile: Codable, Equatable {
    /// Stable identifier for this value.
    public var id: String
    /// Series type associated with this value.
    public var seriesType: String?
    /// Timestamp associated with this value.
    public var time: String?
    /// Value associated with this value.
    public var value: Double?
    /// Created at associated with this value.
    public var createdAt: Date?
    /// Last updated associated with this value.
    public var lastUpdated: Date?
    /// Trade entry ID associated with this value.
    public var tradeEntryId: String?
    /// Instrument ID associated with this value.
    public var instrumentId: String?
    /// Configuration associated with this value.
    public var configId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case seriesType = "series_type"
        case time
        case value
        case createdAt = "created_at"
        case lastUpdated = "last_updated"
        case tradeEntryId = "trade_entry_id"
        case instrumentId = "instrument_id"
        case configId = "config_id"
    }
}

/// Represents `BKV3_SimulationRule` in the BacktestingKit public API.
public struct BKV3_SimulationRule: Codable, Equatable {
    /// Stable identifier for this value.
    public var id: String
    /// Indicator one name associated with this value.
    public var indicatorOneName: String?
    /// Indicator one type associated with this value.
    public var indicatorOneType: String?
    /// Indicator one figure one associated with this value.
    public var indicatorOneFigureOne: Double?
    /// Indicator one figure two associated with this value.
    public var indicatorOneFigureTwo: Double?
    /// Indicator one figure three associated with this value.
    public var indicatorOneFigureThree: Double?
    /// Compare associated with this value.
    public var compare: String?
    /// Indicator two name associated with this value.
    public var indicatorTwoName: String?
    /// Indicator two type associated with this value.
    public var indicatorTwoType: String?
    /// Indicator two figure one associated with this value.
    public var indicatorTwoFigureOne: Double?
    /// Indicator two figure two associated with this value.
    public var indicatorTwoFigureTwo: Double?
    /// Indicator two figure three associated with this value.
    public var indicatorTwoFigureThree: Double?
    /// Created at associated with this value.
    public var createdAt: Date?
    /// Last updated associated with this value.
    public var lastUpdated: Date?
    /// Configuration associated with this value.
    public var configId: String?
    /// Instrument ID associated with this value.
    public var instrumentId: String?
    /// Rule type associated with this value.
    public var ruleType: RuleType?

    enum CodingKeys: String, CodingKey {
        case id
        case indicatorOneName = "indicator_one_name"
        case indicatorOneType = "indicator_one_type"
        case indicatorOneFigureOne = "indicator_one_figure_one"
        case indicatorOneFigureTwo = "indicator_one_figure_two"
        case indicatorOneFigureThree = "indicator_one_figure_three"
        case compare
        case indicatorTwoName = "indicator_two_name"
        case indicatorTwoType = "indicator_two_type"
        case indicatorTwoFigureOne = "indicator_two_figure_one"
        case indicatorTwoFigureTwo = "indicator_two_figure_two"
        case indicatorTwoFigureThree = "indicator_two_figure_three"
        case createdAt = "created_at"
        case lastUpdated = "last_updated"
        case ruleType = "rule_type"
        case configId = "config_id"
        case instrumentId = "instrument_id"
    }
}

/// Represents `RuleType` in the BacktestingKit public API.
public enum RuleType: String, CaseIterable, Codable {
    case entry
    case exit
}

/// Represents `BKV3_TradeEntry` in the BacktestingKit public API.
public struct BKV3_TradeEntry: Codable, Equatable {
    /// Stable identifier for this value.
    public var id: String
    /// Direction associated with this value.
    public var direction: String?
    /// Entry time associated with this value.
    public var entryTime: String?
    /// Entry price associated with this value.
    public var entryPrice: Double?
    /// Exit time associated with this value.
    public var exitTime: String?
    /// Exit price associated with this value.
    public var exitPrice: Double?
    /// Profit associated with this value.
    public var profit: Double?
    /// Profit percentage associated with this value.
    public var profitPct: Double?
    /// Growth associated with this value.
    public var growth: Double?
    /// Risk percentage associated with this value.
    public var riskPct: Double?
    /// Rmultiple associated with this value.
    public var rmultiple: Double?
    /// Holding period associated with this value.
    public var holdingPeriod: Double?
    /// Exit reason associated with this value.
    public var exitReason: String?
    /// Stop price associated with this value.
    public var stopPrice: Double?
    /// Profit target associated with this value.
    public var profitTarget: Double?
    /// Configuration associated with this value.
    public var configId: String?
    /// Last updated associated with this value.
    public var lastUpdated: Date?
    /// Created at associated with this value.
    public var createdAt: Date?
    /// Instrument ID associated with this value.
    public var instrumentId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case direction
        case entryTime = "entry_time"
        case entryPrice = "entry_price"
        case exitTime = "exit_time"
        case exitPrice = "exit_price"
        case profit
        case profitPct = "profit_pct"
        case growth
        case riskPct = "risk_pct"
        case rmultiple
        case holdingPeriod = "holding_period"
        case exitReason = "exit_reason"
        case stopPrice = "stop_price"
        case profitTarget = "profit_target"
        case configId = "config_id"
        case lastUpdated = "last_updated"
        case createdAt = "created_at"
        case instrumentId = "instrument_id"
    }
}

/// Represents `BKV3_UserDevice` in the BacktestingKit public API.
public struct BKV3_UserDevice: Codable, Equatable {
    /// User ID associated with this value.
    public var userId: String?
    /// Device ID associated with this value.
    public var deviceId: String?
    /// Device type associated with this value.
    public var deviceType: DeviceType?
    /// Last updated associated with this value.
    public var lastUpdated: Date?
    /// Created at associated with this value.
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case deviceId = "device_id"
        case deviceType = "device_type"
        case lastUpdated = "last_updated"
        case createdAt = "created_at"
    }
}

/// Represents `DeviceType` in the BacktestingKit public API.
public enum DeviceType: String, CaseIterable, Codable {
    case android
    case ios
}

/// Represents `BKV3_UserProfile` in the BacktestingKit public API.
public struct BKV3_UserProfile: Codable, Equatable {
    /// User ID associated with this value.
    public var userId: UUID
    /// User ID text associated with this value.
    public var userIdText: String?
    /// Tier associated with this value.
    public var tier: TierSet?
    /// Last updated associated with this value.
    public var lastUpdated: Date?
    /// Created at associated with this value.
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userIdText = "user_id_text"
        case tier
        case lastUpdated = "last_updated"
        case createdAt = "created_at"
    }
}

/// Represents `BKV3_UserSubscription` in the BacktestingKit public API.
public struct BKV3_UserSubscription: Codable, Equatable {
    /// Stable identifier for this value.
    public var id: String
    /// Created at associated with this value.
    public var createdAt: Date
    /// Last updated associated with this value.
    public var lastUpdated: Date
    /// Configuration associated with this value.
    public var configId: String
    /// Pin associated with this value.
    public var pin: Bool
    /// User ID associated with this value.
    public var userId: String
    /// Instrument ID associated with this value.
    public var instrumentId: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case lastUpdated = "last_updated"
        case configId = "config_id"
        case pin
        case userId = "user_id"
        case instrumentId = "instrument_id"
    }
}

/// Represents `BKV3_UserDeletion` in the BacktestingKit public API.
public struct BKV3_UserDeletion: Codable, Equatable {
    /// Stable identifier for this value.
    public var id: String
    /// User ID associated with this value.
    public var userId: String
    /// Email associated with this value.
    public var email: String
    /// Last updated associated with this value.
    public var lastUpdated: Date?
    /// Created at associated with this value.
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case email
        case lastUpdated = "last_updated"
        case createdAt = "created_at"
    }
}
