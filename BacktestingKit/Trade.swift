// Trade.swift
// Trade model for backtesting trades

import Foundation

public struct Trade {
    public enum TradeType { case buy, sell }
    public let type: TradeType
    public let entryDate: Date
    public let entryPrice: Double
    public let exitDate: Date?
    public let exitPrice: Double?
    
    public init(type: TradeType, entryDate: Date, entryPrice: Double, exitDate: Date? = nil, exitPrice: Double? = nil) {
        self.type = type
        self.entryDate = entryDate
        self.entryPrice = entryPrice
        self.exitDate = exitDate
        self.exitPrice = exitPrice
    }
}
