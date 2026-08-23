import XCTest
@testable import BacktestingKit

final class BacktestingKitCandleExecutionTests: XCTestCase {
    func testStandaloneSignalsExecuteAtTheNextCandleOpen() {
        let candles = makeCandles(count: 6)
        let result = BacktestingKitManager().backtest(
            candles: candles,
            uuid: "next-open",
            indicators: [],
            entrySignal: { _, current in current.index == 1 },
            exitSignal: { _, current, _ in current.index == 3 }
        )

        XCTAssertEqual(result.trades.count, 1)
        XCTAssertEqual(result.trades[0].entryDate, candles[2].date)
        XCTAssertEqual(result.trades[0].entryPrice, candles[2].open)
        XCTAssertEqual(result.trades[0].exitDate, candles[4].date)
        XCTAssertEqual(result.trades[0].exitPrice, candles[4].open)
    }

    func testFinalCandleExitLeavesThePositionOpen() {
        let candles = makeCandles(count: 4)
        let result = BacktestingKitManager().backtest(
            candles: candles,
            uuid: "pending-exit",
            indicators: [],
            entrySignal: { _, current in current.index == 1 },
            exitSignal: { _, current, _ in current.index == 3 }
        )

        let trade = try? XCTUnwrap(result.trades.first)
        XCTAssertEqual(trade?.entryDate, candles[2].date)
        XCTAssertNil(trade?.exitDate)
        XCTAssertNil(trade?.exitPrice)
        XCTAssertEqual(result.numTrades, 0)
    }

    func testFinalCandleEntrySignalDoesNotCreateAnExecutedTrade() {
        let candles = makeCandles(count: 4)
        let result = BacktestingKitManager().backtest(
            candles: candles,
            uuid: "pending-entry",
            indicators: [],
            entrySignal: { _, current in current.index == 3 },
            exitSignal: { _, _, _ in false }
        )

        XCTAssertTrue(result.trades.isEmpty)
        XCTAssertEqual(result.numTrades, 0)
    }

    private func makeCandles(count: Int) -> [Candlestick] {
        let start = Date(timeIntervalSince1970: 1_704_067_200)
        return (0..<count).map { index in
            let open = 100 + Double(index * 10)
            return Candlestick(
                date: start.addingTimeInterval(Double(index) * 86_400),
                open: open,
                high: open + 5,
                low: open - 5,
                close: open + 2,
                volume: 1_000
            )
        }
    }
}
