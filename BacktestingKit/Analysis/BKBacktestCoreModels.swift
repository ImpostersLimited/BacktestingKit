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
    public var time: Date
    public var open: Double
    public var high: Double
    public var low: Double
    public var close: Double
    public var adjustedClose: Double?
    public var volume: Double
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
    public var recordStopPrice: Bool
    public var recordRisk: Bool

    /// Creates a new instance.
    public init(recordStopPrice: Bool = false, recordRisk: Bool = false) {
        self.recordStopPrice = recordStopPrice
        self.recordRisk = recordRisk
    }
}

/// Represents `BKPosition` in the BacktestingKit public API.
public struct BKPosition {
    public var direction: TradeDirection
    public var entryTime: Date
    public var entryPrice: Double
    public var profit: Double
    public var profitPct: Double
    public var growth: Double
    public var initialUnitRisk: Double?
    public var initialRiskPct: Double?
    public var curRiskPct: Double?
    public var curRMultiple: Double?
    public var riskSeries: [BKTimestampedValue]?
    public var holdingPeriod: Int
    public var initialStopPrice: Double?
    public var curStopPrice: Double?
    public var stopPriceSeries: [BKTimestampedValue]?
    public var profitTarget: Double?
}

/// Provides the `EnterPositionFn` typealias for BacktestingKit interoperability.
public typealias EnterPositionFn = (_ options: BKEnterPositionOptions?) -> Void
/// Provides the `ExitPositionFn` typealias for BacktestingKit interoperability.
public typealias ExitPositionFn = () -> Void

/// Represents `BKEnterPositionOptions` in the BacktestingKit public API.
public struct BKEnterPositionOptions {
    public var direction: TradeDirection?
    public var entryPrice: Double?

    /// Creates a new instance.
    public init(direction: TradeDirection? = nil, entryPrice: Double? = nil) {
        self.direction = direction
        self.entryPrice = entryPrice
    }
}

/// Represents `BKRuleParams` in the BacktestingKit public API.
public struct BKRuleParams {
    public var bar: BKBar
    public var lookback: [BKBar]
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
    public var entryPrice: Double
    public var position: BKPosition
    public var bar: BKBar
    public var lookback: [BKBar]
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
    public var parameters: [String: Double]
    public var lookbackPeriod: Int
    public var prepIndicators: ((_ input: [BKBar], _ parameters: [String: Double]) -> [BKBar])?
    public var entryRule: BKEntryRuleFn
    public var exitRule: BKExitRuleFn?
    public var stopLoss: BKStopLossFn?
    public var trailingStopLoss: BKStopLossFn?
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
