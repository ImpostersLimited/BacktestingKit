import Foundation

/// Represents `TradeDirection` in the BacktestingKit public API.
public enum TradeDirection: String, Codable {
    case long
    case short
}

/// Represents `PositionStatus` in the BacktestingKit public API.
public enum PositionStatus: String, Codable {
    case enter = "Enter"
    case none = "None"
    case position = "Position"
    case exit = "Exit"
}

/// Represents `BKBar` in the BacktestingKit public API.
public struct BKBar: Codable, Equatable {
    /// Timestamp associated with this value.
    public var time: Date
    /// Open price for the bar.
    public var open: Double
    /// High price for the bar.
    public var high: Double
    /// Low price for the bar.
    public var low: Double
    /// Close price for the bar.
    public var close: Double
    /// Adjusted close price for the bar when available.
    public var adjustedClose: Double?
    /// Trading volume for the bar.
    public var volume: Double
    /// Indicators associated with this value.
    public var indicators: [String: Double]

    /// Creates a new instance.
    public init(
        time: Date,
        open: Double,
        high: Double,
        low: Double,
        close: Double,
        adjustedClose: Double? = nil,
        volume: Double,
        indicators: [String: Double] = [:]
    ) {
        self.time = time
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.adjustedClose = adjustedClose
        self.volume = volume
        self.indicators = indicators
    }

    /// Executes `value`.
    public func value(forName name: String) -> Double? {
        switch name {
        case "open": return open
        case "high": return high
        case "low": return low
        case "close": return close
        case "adjustedClose", "adjusted_close", "adjClose", "adj_close": return adjustedClose
        case "volume": return volume
        default: return indicators[name]
        }
    }
}

/// Represents `BKBacktestOptions` in the BacktestingKit public API.
public struct BKBacktestOptions {
    /// Whether to record stop price.
    public var recordStopPrice: Bool
    /// Whether to record risk.
    public var recordRisk: Bool

    /// Creates a new instance.
    public init(recordStopPrice: Bool = false, recordRisk: Bool = false) {
        self.recordStopPrice = recordStopPrice
        self.recordRisk = recordRisk
    }
}

/// Represents `BKPosition` in the BacktestingKit public API.
public struct BKPosition {
    /// Direction associated with this value.
    public var direction: TradeDirection
    /// Entry time associated with this value.
    public var entryTime: Date
    /// Entry price associated with this value.
    public var entryPrice: Double
    /// Profit associated with this value.
    public var profit: Double
    /// Profit percentage associated with this value.
    public var profitPct: Double
    /// Growth associated with this value.
    public var growth: Double
    /// Initial unit risk associated with this value.
    public var initialUnitRisk: Double?
    /// Initial risk percentage associated with this value.
    public var initialRiskPct: Double?
    /// Current risk percentage associated with this value.
    public var curRiskPct: Double?
    /// Current r multiple associated with this value.
    public var curRMultiple: Double?
    /// Risk series associated with this value.
    public var riskSeries: [BKTimestampedValue]?
    /// Holding period associated with this value.
    public var holdingPeriod: Int
    /// Initial stop price associated with this value.
    public var initialStopPrice: Double?
    /// Current stop price associated with this value.
    public var curStopPrice: Double?
    /// Stop price series associated with this value.
    public var stopPriceSeries: [BKTimestampedValue]?
    /// Profit target associated with this value.
    public var profitTarget: Double?
}

/// Provides the `EnterPositionFn` typealias for BacktestingKit interoperability.
public typealias EnterPositionFn = (_ options: BKEnterPositionOptions?) -> Void
/// Provides the `ExitPositionFn` typealias for BacktestingKit interoperability.
public typealias ExitPositionFn = () -> Void

/// Represents `BKEnterPositionOptions` in the BacktestingKit public API.
public struct BKEnterPositionOptions {
    /// Direction associated with this value.
    public var direction: TradeDirection?
    /// Entry price associated with this value.
    public var entryPrice: Double?

    /// Creates a new instance.
    public init(direction: TradeDirection? = nil, entryPrice: Double? = nil) {
        self.direction = direction
        self.entryPrice = entryPrice
    }
}

/// Represents `BKRuleParams` in the BacktestingKit public API.
public struct BKRuleParams {
    /// Bar associated with this value.
    public var bar: BKBar
    /// Lookback associated with this value.
    public var lookback: [BKBar]
    /// Parameters associated with this value.
    public var parameters: [String: Double]

    /// Creates a new instance.
    public init(bar: BKBar, lookback: [BKBar], parameters: [String: Double]) {
        self.bar = bar
        self.lookback = lookback
        self.parameters = parameters
    }
}

/// Represents `BKOpenPositionRuleArgs` in the BacktestingKit public API.
public struct BKOpenPositionRuleArgs {
    /// Entry price associated with this value.
    public var entryPrice: Double
    /// Position associated with this value.
    public var position: BKPosition
    /// Bar associated with this value.
    public var bar: BKBar
    /// Lookback associated with this value.
    public var lookback: [BKBar]
    /// Parameters associated with this value.
    public var parameters: [String: Double]
}

/// Provides the `BKEntryRuleFn` typealias for BacktestingKit interoperability.
public typealias BKEntryRuleFn = (_ enterPosition: EnterPositionFn, _ args: BKRuleParams) -> Void
/// Provides the `BKExitRuleFn` typealias for BacktestingKit interoperability.
public typealias BKExitRuleFn = (_ exitPosition: ExitPositionFn, _ args: BKOpenPositionRuleArgs) -> Void
/// Provides the `BKStopLossFn` typealias for BacktestingKit interoperability.
public typealias BKStopLossFn = (_ args: BKOpenPositionRuleArgs) -> Double
/// Provides the `BKProfitTargetFn` typealias for BacktestingKit interoperability.
public typealias BKProfitTargetFn = (_ args: BKOpenPositionRuleArgs) -> Double

/// Represents `BKStrategy` in the BacktestingKit public API.
public struct BKStrategy {
    /// Parameters associated with this value.
    public var parameters: [String: Double]
    /// Lookback period associated with this value.
    public var lookbackPeriod: Int
    /// Prep indicators associated with this value.
    public var prepIndicators: ((_ input: [BKBar], _ parameters: [String: Double]) -> [BKBar])?
    /// Entry rule associated with this value.
    public var entryRule: BKEntryRuleFn
    /// Exit rule associated with this value.
    public var exitRule: BKExitRuleFn?
    /// Stop loss associated with this value.
    public var stopLoss: BKStopLossFn?
    /// Trailing stop loss associated with this value.
    public var trailingStopLoss: BKStopLossFn?
    /// Profit target associated with this value.
    public var profitTarget: BKProfitTargetFn?

    /// Creates a new instance.
    public init(
        parameters: [String: Double] = [:],
        lookbackPeriod: Int = 1,
        prepIndicators: ((_ input: [BKBar], _ parameters: [String: Double]) -> [BKBar])? = nil,
        entryRule: @escaping BKEntryRuleFn,
        exitRule: BKExitRuleFn? = nil,
        stopLoss: BKStopLossFn? = nil,
        trailingStopLoss: BKStopLossFn? = nil,
        profitTarget: BKProfitTargetFn? = nil
    ) {
        self.parameters = parameters
        self.lookbackPeriod = lookbackPeriod
        self.prepIndicators = prepIndicators
        self.entryRule = entryRule
        self.exitRule = exitRule
        self.stopLoss = stopLoss
        self.trailingStopLoss = trailingStopLoss
        self.profitTarget = profitTarget
    }
}
