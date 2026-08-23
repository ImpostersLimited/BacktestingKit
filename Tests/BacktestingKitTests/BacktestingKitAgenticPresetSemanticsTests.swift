import XCTest
@testable import BacktestingKit

final class BacktestingKitAgenticPresetSemanticsTests: XCTestCase {
    func testPublicAgenticPresetsRejectNonPositivePeriods() {
        let manager = BacktestingKitManager()
        let candles = makeCandles(count: 80)
        let calls: [(String, (Int) -> BacktestResult)] = [
            ("pulse pulse", { manager.backtestPulseDipRebound(candles: candles, pulsePeriod: $0) }),
            ("pulse trend", { manager.backtestPulseDipRebound(candles: candles, trendPeriod: $0) }),
            ("pulse RSI", { manager.backtestPulseDipRebound(candles: candles, rsiPeriod: $0) }),
            ("drift fast", { manager.backtestDriftBreather(candles: candles, fastPeriod: $0) }),
            ("drift slow", { manager.backtestDriftBreather(candles: candles, slowPeriod: $0) }),
            ("drift ATR", { manager.backtestDriftBreather(candles: candles, atrPeriod: $0) }),
            ("volatility ATR", { manager.backtestVolatilitySnap(candles: candles, atrPeriod: $0) }),
            ("volatility baseline", { manager.backtestVolatilitySnap(candles: candles, atrBaselinePeriod: $0) }),
            ("band", { manager.backtestBandVWAPBridge(candles: candles, period: $0) }),
            ("echo channel", { manager.backtestEchoChannelPivot(candles: candles, channelPeriod: $0) }),
            ("echo signal", { manager.backtestEchoChannelPivot(candles: candles, signalPeriod: $0) }),
            ("ladder ATR", { manager.backtestLadderCompressionRelease(candles: candles, atrPeriod: $0) }),
            ("ladder baseline", { manager.backtestLadderCompressionRelease(candles: candles, baselinePeriod: $0) }),
            ("RSI latch", { manager.backtestRSIImpulseLatch(candles: candles, rsiPeriod: $0) }),
            ("dual anchor", { manager.backtestDualAnchorSlipstream(candles: candles, trendPeriod: $0) }),
            ("ATR trail EMA", { manager.backtestAtrPulseTrail(candles: candles, emaPeriod: $0) }),
            ("ATR trail ATR", { manager.backtestAtrPulseTrail(candles: candles, atrPeriod: $0) }),
            ("slope fast", { manager.backtestSlopeSwitch(candles: candles, fastPeriod: $0) }),
            ("slope slow", { manager.backtestSlopeSwitch(candles: candles, slowPeriod: $0) }),
            ("vol skew MFI", { manager.backtestVolSkewRebound(candles: candles, mfiPeriod: $0) }),
            ("vol skew trend", { manager.backtestVolSkewRebound(candles: candles, trendPeriod: $0) }),
            ("median band", { manager.backtestMedianBandClimb(candles: candles, period: $0) }),
            ("range", { manager.backtestRangeSnapback(candles: candles, rangePeriod: $0) }),
            ("range EMA", { manager.backtestRangeSnapback(candles: candles, emaPeriod: $0) }),
            ("momentum fast", { manager.backtestMomentumValve(candles: candles, fast: $0) }),
            ("momentum slow", { manager.backtestMomentumValve(candles: candles, slow: $0) }),
            ("momentum signal", { manager.backtestMomentumValve(candles: candles, signal: $0) })
        ]

        for invalidPeriod in [0, -1] {
            for (name, call) in calls {
                XCTAssertEqual(call(invalidPeriod).numTrades, 0, "\(name), period \(invalidPeriod)")
            }
        }
    }

    func testVolatilitySnapRequiresItsSMA55InputMinimum() {
        let metrics = RecordingMetricsCalculator()
        let manager = BacktestingKitManager(backtestMetricsCalculator: metrics)

        _ = manager.backtestVolatilitySnap(candles: makeCandles(count: 54))
        _ = manager.backtestVolatilitySnap(candles: makeCandles(count: 55))

        XCTAssertEqual(metrics.makeResultCandleCounts, [55])
        XCTAssertEqual(metrics.emptyResultCallCount, 1)
    }

    func testEchoChannelPivotRequiresAReclaimFromBelowTheChannelLevel() {
        XCTAssertFalse(bkIsEchoChannelPivotReclaim(previousClose: 102, close: 103, signal: 101, channelLow: 99))
        XCTAssertTrue(bkIsEchoChannelPivotReclaim(previousClose: 98.5, close: 102, signal: 101, channelLow: 98))
        XCTAssertFalse(bkIsEchoChannelPivotReclaim(previousClose: 98.5, close: 100, signal: 101, channelLow: 98))
    }

    func testLadderCompressionReleaseRequiresPriorATRCompression() {
        XCTAssertFalse(bkIsLadderCompressionRelease(previousATR: 4, previousBaseline: 3.5, atr: 10, baseline: 7))
        XCTAssertTrue(bkIsLadderCompressionRelease(previousATR: 1, previousBaseline: 2, atr: 5, baseline: 3))
        XCTAssertFalse(bkIsLadderCompressionRelease(previousATR: 1, previousBaseline: 2, atr: 3.5, baseline: 3))
    }

    private func makeCandles(count: Int) -> [Candlestick] {
        (0..<count).map { index in
            candle(index, close: 100 + Double(index), high: 102 + Double(index), low: 99 + Double(index))
        }
    }

    private func candle(_ index: Int, close: Double, high: Double, low: Double) -> Candlestick {
        Candlestick(
            date: Date(timeIntervalSince1970: Double(index) * 86_400),
            open: close,
            high: high,
            low: low,
            close: close,
            adjustedClose: close,
            volume: 1_000
        )
    }
}

private final class RecordingMetricsCalculator: BKBacktestMetricsCalculating {
    private let base = BKBacktestMetricsCalculator()
    private(set) var emptyResultCallCount = 0
    private(set) var makeResultCandleCounts: [Int] = []

    func emptyResult() -> BacktestResult {
        emptyResultCallCount += 1
        return base.emptyResult()
    }

    func makeResult(trades: [Trade], candles: [Candlestick]) -> BacktestResult {
        makeResultCandleCounts.append(candles.count)
        return base.makeResult(trades: trades, candles: candles)
    }

    func makeReport(trades: [Trade], candles: [Candlestick]) -> BacktestMetricsReport {
        base.makeReport(trades: trades, candles: candles)
    }
}
