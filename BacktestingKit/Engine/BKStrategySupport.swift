import Foundation

/// Internal helper for strategy implementations that manage open/close trades manually.
/// Keeps trade lifecycle logic in one place so strategy methods can focus on signals.
struct BKTradeLifecycle {
    private(set) var trades: [Trade] = []

    mutating func openLong(entryDate: Date, entryPrice: Double) {
        trades.append(Trade(type: .buy, entryDate: entryDate, entryPrice: entryPrice))
    }

    mutating func closeLatestOpen(exitDate: Date, exitPrice: Double) {
        guard let idx = trades.lastIndex(where: { $0.exitDate == nil }) else { return }
        let open = trades[idx]
        trades[idx] = Trade(
            type: open.type,
            entryDate: open.entryDate,
            entryPrice: open.entryPrice,
            exitDate: exitDate,
            exitPrice: exitPrice
        )
    }
}

extension BacktestingKitManager {
    /// Shared empty-result fallback used by preset helpers when input cannot be simulated.
    func bkEmptyBacktestResult() -> BacktestResult {
        backtestSMACrossover(candles: [], fast: 1, slow: 2)
    }
}
