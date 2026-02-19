// Trade.swift
// Trade model for backtesting trades

import Foundation

/// Represents `Trade` in the BacktestingKit public API.
public struct Trade {
    /// Represents `TradeType` in the BacktestingKit public API.
    public enum TradeType { case buy, sell }
    public let type: TradeType
    public let entryDate: Date
    public let entryPrice: Double
    public let exitDate: Date?
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
