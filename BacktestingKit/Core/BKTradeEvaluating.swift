import Foundation

/// Defines the `BKTradeEvaluating` contract used by BacktestingKit.
public protocol BKTradeEvaluating {
    var entryDate: Date { get }
    var entryPrice: Double { get }
    var exitDate: Date? { get }
    var exitPrice: Double? { get }
}

public extension BKTradeEvaluating {
    var bkReturn: Double? {
        guard let exitPrice else { return nil }
        return (exitPrice - entryPrice) / entryPrice
    }

    func bkHoldingPeriodDays(calendar: Calendar = .current) -> Double? {
        guard let exitDate else { return nil }
        let days = calendar.dateComponents([.day], from: entryDate, to: exitDate).day ?? 0
        return Double(max(days, 0))
    }
}
