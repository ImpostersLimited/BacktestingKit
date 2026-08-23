import Foundation

enum BKPendingTradeAction: Equatable {
    case entry
    case exit
}

/// Internal helper for strategy implementations that manage open/close trades manually.
/// Keeps trade lifecycle logic in one place so strategy methods can focus on signals.
struct BKTradeLifecycle {
    private(set) var trades: [Trade] = []
    private var pendingAction: BKPendingTradeAction?

    var isInPosition: Bool {
        guard let latestTrade = trades.last else { return false }
        return latestTrade.exitDate == nil
    }

    mutating func requestEntry() {
        guard !isInPosition, pendingAction == nil else { return }
        pendingAction = .entry
    }

    mutating func requestExit() {
        guard isInPosition, pendingAction == nil else { return }
        pendingAction = .exit
    }

    mutating func executePending(at candle: Candlestick) -> BKPendingTradeAction? {
        guard let action = pendingAction else { return nil }
        pendingAction = nil

        switch action {
        case .entry:
            openLong(entryDate: candle.date, entryPrice: candle.open)
        case .exit:
            closeLatestOpen(exitDate: candle.date, exitPrice: candle.open)
        }
        return action
    }

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
