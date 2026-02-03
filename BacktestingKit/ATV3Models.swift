import Foundation

public struct ATV3_AnalysisProfile: Codable, Equatable {
    public var id: String
    public var startingCapital: Double?
    public var finalCapital: Double?
    public var profit: Double?
    public var profitPct: Double?
    public var growth: Double?
    public var totalTrades: Double?
    public var barCount: Double?
    public var maxDrawdown: Double?
    public var maxDrawdownPct: Double?
    public var maxRiskPct: Double?
    public var expectency: Double?
    public var rmultipleStdDev: Double?
    public var systemQuality: Double?
    public var profitFactor: Double?
    public var proportionProfitable: Double?
    public var percentProfitable: Double?
    public var returnOnAccount: Double?
    public var averageProfitPerTrade: Double?
    public var numWinningTrades: Double?
    public var numLosingTrades: Double?
    public var averageWinningTrade: Double?
    public var averageLosingTrade: Double?
    public var expectedValue: Double?
    public var maxDownDrawNew: Double?
    public var maxDownDrawPctNew: Double?
    public var createdAt: Date?
    public var lastUpdated: Date?
    public var configId: String?
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

public struct ATV3_Config: Codable, Equatable {
    public var id: String
    public var active: Bool?
    public var createdAt: Date?
    public var instrumentId: String?
    public var lastUpdated: Date?
    public var status: String?
    public var optimizeResultId: String?
    public var policy: SimulationPolicy?
    public var lastStatus: PositionStatus?
    public var trailingStopLoss: Bool?
    public var stopLossFigure: Double?
    public var profitFactor: Double?
    public var t1: Double?
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

public struct ATV3_InstrumentInfo: Codable, Equatable {
    public var id: String
    public var name: String?
    public var exchange: String?
    public var quoteType: String?
    public var createdAt: Date?
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

public struct ATV3_OptimizePolicyConfig: Codable, Equatable {
    public var id: String
    public var stepSize: Int?
    public var simplePolicy: Bool?
    public var trailingStopLoss: Bool?
    public var stopLossFigure: Double?
    public var profitFactor: Double?
    public var t1: Double?
    public var t2: Double?
    public var createdAt: Date?
    public var lastUpdated: Date?
    public var optimizeResultId: String?
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

public struct ATV3_OptimizeResult: Codable, Equatable {
    public var id: String
    public var status: String?
    public var createdAt: Date?
    public var lastUpdated: Date?
    public var instrumentId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case createdAt = "created_at"
        case lastUpdated = "last_updated"
        case instrumentId = "instrument_id"
    }
}

public struct ATV3_OptimizeRule: Codable, Equatable {
    public var id: String
    public var indicatorOneName: String?
    public var indicatorOneType: String?
    public var indicatorOneFigureLowerOne: Double?
    public var indicatorOneFigureLowerTwo: Double?
    public var indicatorOneFigureLowerThree: Double?
    public var indicatorOneFigureUpperOne: Double?
    public var indicatorOneFigureUpperTwo: Double?
    public var indicatorOneFigureUpperThree: Double?
    public var compare: String?
    public var indicatorTwoName: String?
    public var indicatorTwoType: String?
    public var indicatorTwoFigureLowerOne: Double?
    public var indicatorTwoFigureLowerTwo: Double?
    public var indicatorTwoFigureLowerThree: Double?
    public var indicatorTwoFigureUpperOne: Double?
    public var indicatorTwoFigureUpperTwo: Double?
    public var indicatorTwoFigureUpperThree: Double?
    public var createdAt: Date?
    public var lastUpdated: Date?
    public var optimizePolicyConfigId: String?
    public var ruleType: RuleType?
    public var instrumentId: String?
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

public struct ATV3_RiskProfile: Codable, Equatable {
    public var id: String
    public var seriesType: String?
    public var time: String?
    public var value: Double?
    public var createdAt: Date?
    public var lastUpdated: Date?
    public var tradeEntryId: String?
    public var instrumentId: String?
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

public struct ATV3_SimulationRule: Codable, Equatable {
    public var id: String
    public var indicatorOneName: String?
    public var indicatorOneType: String?
    public var indicatorOneFigureOne: Double?
    public var indicatorOneFigureTwo: Double?
    public var indicatorOneFigureThree: Double?
    public var compare: String?
    public var indicatorTwoName: String?
    public var indicatorTwoType: String?
    public var indicatorTwoFigureOne: Double?
    public var indicatorTwoFigureTwo: Double?
    public var indicatorTwoFigureThree: Double?
    public var createdAt: Date?
    public var lastUpdated: Date?
    public var configId: String?
    public var instrumentId: String?
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

public enum RuleType: String, CaseIterable, Codable {
    case entry
    case exit
}

public struct ATV3_TradeEntry: Codable, Equatable {
    public var id: String
    public var direction: String?
    public var entryTime: String?
    public var entryPrice: Double?
    public var exitTime: String?
    public var exitPrice: Double?
    public var profit: Double?
    public var profitPct: Double?
    public var growth: Double?
    public var riskPct: Double?
    public var rmultiple: Double?
    public var holdingPeriod: Double?
    public var exitReason: String?
    public var stopPrice: Double?
    public var profitTarget: Double?
    public var configId: String?
    public var lastUpdated: Date?
    public var createdAt: Date?
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

public struct ATV3_UserDevice: Codable, Equatable {
    public var userId: String?
    public var deviceId: String?
    public var deviceType: DeviceType?
    public var lastUpdated: Date?
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case deviceId = "device_id"
        case deviceType = "device_type"
        case lastUpdated = "last_updated"
        case createdAt = "created_at"
    }
}

public enum DeviceType: String, CaseIterable, Codable {
    case android
    case ios
}

public struct ATV3_UserProfile: Codable, Equatable {
    public var userId: UUID
    public var userIdText: String?
    public var tier: TierSet?
    public var lastUpdated: Date?
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userIdText = "user_id_text"
        case tier
        case lastUpdated = "last_updated"
        case createdAt = "created_at"
    }
}

public struct ATV3_UserSubscription: Codable, Equatable {
    public var id: String
    public var createdAt: Date
    public var lastUpdated: Date
    public var configId: String
    public var pin: Bool
    public var userId: String
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

public struct ATV3_UserDeletion: Codable, Equatable {
    public var id: String
    public var userId: String
    public var email: String
    public var lastUpdated: Date?
    public var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case email
        case lastUpdated = "last_updated"
        case createdAt = "created_at"
    }
}

