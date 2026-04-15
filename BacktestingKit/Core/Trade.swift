// Trade.swift
// Trade model for backtesting trades

import Foundation

/// Represents `Trade` in the BacktestingKit public API.
public struct Trade {
    /// Represents `TradeType` in the BacktestingKit public API.
    public enum TradeType { case buy, sell }
    /// Type associated with this value.
    public let type: TradeType
    /// Entry date associated with this value.
    public let entryDate: Date
    /// Entry price associated with this value.
    public let entryPrice: Double
    /// Exit date associated with this value.
    public let exitDate: Date?
    /// Exit price associated with this value.
    public let exitPrice: Double?

    /// Creates a new instance.
    public init(type: TradeType, entryDate: Date, entryPrice: Double, exitDate: Date? = nil, exitPrice: Double? = nil) {
        self.type = type
        self.entryDate = entryDate
        self.entryPrice = entryPrice
        self.exitDate = exitDate
        self.exitPrice = exitPrice
    }
}

extension Trade: BKTradeEvaluating {}
