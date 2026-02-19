import Foundation

/// Represents `TechnicalIndicator` in the BacktestingKit public API.
public enum TechnicalIndicator: Hashable, Identifiable, Equatable, Codable, CustomStringConvertible, CaseIterable {
    case sma(period: Int)

    public static var allCases: [TechnicalIndicator] {
        // Only representative cases without associated values
        // (users can extend as needed)
        [.sma(period: 0)]
    }
    public var id: Int {
        switch self {
        case .sma(let period): return period.hashValue ^ 0x1000
        }
    }
    public var description: String {
        switch self {
        case .sma(let period): return "SMA(\(period))"
        }
    }
}

/// Represents `StrategyOperand` in the BacktestingKit public API.
public enum StrategyOperand: Hashable, Identifiable, Equatable, Codable, CustomStringConvertible, CaseIterable {
    case indicator(TechnicalIndicator)
    case price(TechnicalIndicatorValueProvider.PriceType)
    case constant(Double)

    public static var allCases: [StrategyOperand] {
        [.indicator(.sma(period: 0)), .price(.open), .constant(0)]
    }
    public var id: Int {
        switch self {
        case .indicator(let ti): return ti.id ^ 0x2000
        case .price(let pt): return pt.id ^ 0x2100
        case .constant(let d): return Int(truncatingIfNeeded: d.bitPattern)
        }
    }
    public var description: String {
        switch self {
        case .indicator(let ti): return "Indicator(\(ti))"
        case .price(let pt): return "Price(\(pt))"
        case .constant(let d): return "Constant(\(d))"
        }
    }
}

/// Represents `StrategyOperator` in the BacktestingKit public API.
public enum StrategyOperator: Hashable, Identifiable, Equatable, Codable, CustomStringConvertible, CaseIterable {
    case greaterThan
    case lessThan
    case greaterThanOrEqual
    case lessThanOrEqual
    public static var allCases: [StrategyOperator] {
        [.greaterThan, .lessThan, .greaterThanOrEqual, .lessThanOrEqual]
    }
    public var id: Int {
        switch self {
        case .greaterThan: return 0
        case .lessThan: return 1
        case .greaterThanOrEqual: return 2
        case .lessThanOrEqual: return 3
        }
    }
    public var description: String {
        switch self {
        case .greaterThan: return ">"
        case .lessThan: return "<"
        case .greaterThanOrEqual: return ">="
        case .lessThanOrEqual: return "<="
        }
    }
}

// Nested enum
extension TechnicalIndicatorValueProvider.PriceType: Hashable, Identifiable, Equatable, Codable, CustomStringConvertible, CaseIterable {
    public static var allCases: [Self] { [.open, .high, .low, .close, .volume] }
    public var id: Int { self.hashValue }
    public var description: String {
        switch self {
        case .open: return "Open"
        case .high: return "High"
        case .low: return "Low"
        case .close: return "Close"
        case .volume: return "Volume"
        }
    }
}

/// Represents `StrategyCondition` in the BacktestingKit public API.
public struct StrategyCondition: Hashable, Identifiable, Equatable, Codable {
    public let lhs: StrategyOperand
    public let op: StrategyOperator
    public let rhs: StrategyOperand
    /// Creates a new instance.
    public init(_ lhs: StrategyOperand, _ op: StrategyOperator, _ rhs: StrategyOperand) {
        self.lhs = lhs
        self.op = op
        self.rhs = rhs
    }
    public var id: Int { lhs.id ^ op.id ^ rhs.id }
}

/// Represents `TechnicalIndicatorValueProvider` in the BacktestingKit public API.
public struct TechnicalIndicatorValueProvider: Identifiable, Equatable, Codable {
    public let index: Int
    public let candles: [Candlestick]
    public let indicatorNameMap: [TechnicalIndicator: String]
    /// Executes `value`.
    public func value(for indicator: TechnicalIndicator) -> Double? {
        guard candles.indices.contains(index) else { return nil }
        guard let name = indicatorNameMap[indicator] else { return nil }
        return candles[index].technicalIndicators[name]
    }
    /// Executes `price`.
    public func price(_ type: PriceType) -> Double {
        guard candles.indices.contains(index) else { return 0 }
        let candle = candles[index]
        switch type {
        case .open: return candle.open
        case .high: return candle.high
        case .low: return candle.low
        case .close: return candle.close
        case .volume: return candle.volume
        }
    }
    /// Represents `PriceType` in the BacktestingKit public API.
    public enum PriceType { case open, high, low, close, volume }
    public var id: Int { index }
}
