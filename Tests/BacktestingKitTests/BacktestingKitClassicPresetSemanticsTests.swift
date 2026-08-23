import XCTest
@testable import BacktestingKit

final class BacktestingKitClassicPresetSemanticsTests: XCTestCase {
    func testSupertrendUsesPreviousBandToDetermineTrendState() {
        let prices: [(high: Double, low: Double, close: Double)] = [
            (112, 108, 110),
            (93, 88, 90),
            (95, 91, 94),
            (105, 101, 102),
            (92, 87, 90),
            (95, 90, 94),
            (96, 92, 95),
            (111, 105, 107)
        ]
        let candles = prices.enumerated().map { index, price in
            candle(index: index, high: price.high, low: price.low, close: price.close)
        }

        let result = BacktestingKitManager().bkSupertrendCandles(
            candles,
            atrPeriod: 1,
            multiplier: 1.5,
            uuid: "test"
        )

        XCTAssertEqual(result[2].technicalIndicators["supertrend_1_test"], 100.5)
        XCTAssertEqual(result[3].technicalIndicators["supertrend_1_test"], 86.5)
    }

    func testSupertrendInitializesAtTheFirstAvailableATR() {
        let candles = [
            candle(index: 0, high: 112, low: 108, close: 110),
            candle(index: 1, high: 93, low: 88, close: 90),
            candle(index: 2, high: 95, low: 91, close: 94)
        ]

        let result = BacktestingKitManager().bkSupertrendCandles(
            candles,
            atrPeriod: 2,
            multiplier: 1.5,
            uuid: "warmup"
        )

        XCTAssertNil(result[0].technicalIndicators["supertrend_2_warmup"])
        XCTAssertEqual(result[1].technicalIndicators["supertrend_2_warmup"], 71)
    }

    func testPublicPresetStrategiesRejectNonPositivePeriods() {
        let manager = BacktestingKitManager()
        let candles = (0..<320).map { candle(index: $0, high: 102, low: 98, close: 100) }
        let checks: [(String, (Int) -> BacktestResult)] = [
            ("Donchian breakout period", { manager.backtestDonchianBreakoutWithATRStop(candles: candles, breakoutPeriod: $0) }),
            ("Donchian ATR period", { manager.backtestDonchianBreakoutWithATRStop(candles: candles, atrPeriod: $0) }),
            ("Supertrend ATR period", { manager.backtestSupertrend(candles: candles, atrPeriod: $0) }),
            ("Dual EMA fast period", { manager.backtestDualEMAWithADXFilter(candles: candles, fastPeriod: $0) }),
            ("Dual EMA slow period", { manager.backtestDualEMAWithADXFilter(candles: candles, slowPeriod: $0) }),
            ("Dual EMA ADX period", { manager.backtestDualEMAWithADXFilter(candles: candles, adxPeriod: $0) }),
            ("Bollinger z-score period", { manager.backtestBollingerZScoreMeanReversion(candles: candles, period: $0) }),
            ("RSI2 trend period", { manager.backtestRSI2MeanReversion(candles: candles, trendPeriod: $0) }),
            ("EMA ATR fast period", { manager.backtestEMAFastSlowWithATRStop(candles: candles, fastPeriod: $0) }),
            ("EMA ATR slow period", { manager.backtestEMAFastSlowWithATRStop(candles: candles, slowPeriod: $0) }),
            ("EMA ATR ATR period", { manager.backtestEMAFastSlowWithATRStop(candles: candles, atrPeriod: $0) }),
            ("EMA 12/26 ATR period", { manager.backtestEMA1226WithATRStop(candles: candles, atrPeriod: $0) }),
            ("Turtle entry period", { manager.backtestDonchianBreakoutWithATRStop(candles: candles, entryPeriod: $0) }),
            ("Turtle exit period", { manager.backtestDonchianBreakoutWithATRStop(candles: candles, exitPeriod: $0) }),
            ("Turtle ATR period", { manager.backtestDonchianBreakoutWithATRStop(candles: candles, entryPeriod: 55, exitPeriod: 20, atrPeriod: $0) }),
            ("Donchian 20/55 entry period", { manager.backtestDonchian2055WithATRPositionSizing(candles: candles, entryPeriod: $0) }),
            ("Donchian 20/55 exit period", { manager.backtestDonchian2055WithATRPositionSizing(candles: candles, exitPeriod: $0) }),
            ("Donchian 20/55 ATR period", { manager.backtestDonchian2055WithATRPositionSizing(candles: candles, atrPeriod: $0) }),
            ("SMA regime fast period", { manager.backtestSMACrossoverWithRegimeFilter(candles: candles, fastPeriod: $0) }),
            ("SMA regime slow period", { manager.backtestSMACrossoverWithRegimeFilter(candles: candles, slowPeriod: $0) }),
            ("SMA regime ADX period", { manager.backtestSMACrossoverWithRegimeFilter(candles: candles, adxPeriod: $0) }),
            ("Bollinger reversion period", { manager.backtestBollingerBandReversion(candles: candles, period: $0) }),
            ("Z-score lookback", { manager.backtestZScoreReversion(candles: candles, lookback: $0) }),
            ("VWAP rolling period", { manager.backtestVWAPReversion(candles: candles, rollingStdPeriod: $0) }),
            ("OBV breakout period", { manager.backtestOBVTrendConfirmationBreakout(candles: candles, breakoutPeriod: $0) }),
            ("OBV SMA period", { manager.backtestOBVTrendConfirmationBreakout(candles: candles, obvSmaPeriod: $0) }),
            ("MFI period", { manager.backtestMFITrendFilterReversion(candles: candles, mfiPeriod: $0) }),
            ("MFI trend period", { manager.backtestMFITrendFilterReversion(candles: candles, trendPeriod: $0) }),
            ("Volatility ATR period", { manager.backtestVolatilityContractionBreakout(candles: candles, atrPeriod: $0) }),
            ("Volatility ATR SMA period", { manager.backtestVolatilityContractionBreakout(candles: candles, atrSmaPeriod: $0) }),
            ("Volatility breakout period", { manager.backtestVolatilityContractionBreakout(candles: candles, breakoutPeriod: $0) }),
            ("Volatility exit SMA period", { manager.backtestVolatilityContractionBreakout(candles: candles, exitSmaPeriod: $0) })
        ]

        for invalidPeriod in [0, -1] {
            for (name, run) in checks {
                XCTAssertTrue(run(invalidPeriod).trades.isEmpty, "\(name) accepted \(invalidPeriod)")
            }
        }
    }

    func testVWAPReversionResetsVWAPAtEachUTCSession() throws {
        let base = Date(timeIntervalSince1970: 1_704_067_200)
        let values: [(day: Int, high: Double, low: Double, close: Double, volume: Double)] = [
            (0, 104, 98, 101, 500),
            (0, 104, 99, 103, 200),
            (0, 96, 84, 90, 500),
            (0, 103, 94, 99, 400),
            (1, 101, 94, 95, 200),
            (1, 95, 85, 92, 400),
            (1, 108, 96, 104, 100),
            (1, 97, 92, 94, 400)
        ]
        let candles = values.enumerated().map { index, value in
            Candlestick(
                date: base.addingTimeInterval(Double(value.day * 86_400 + (index % 4) * 3_600)),
                open: value.close,
                high: value.high,
                low: value.low,
                close: value.close,
                volume: value.volume
            )
        }

        let result = BacktestingKitManager().bkSessionAnchoredVWAP(candles, uuid: "test")
        let firstSessionVWAP = try XCTUnwrap(result[4].technicalIndicators["vwap_test"])
        let secondSessionVWAP = try XCTUnwrap(result[5].technicalIndicators["vwap_test"])

        XCTAssertEqual(firstSessionVWAP, 96.666_666_666_666_67, accuracy: 0.000_001)
        XCTAssertEqual(secondSessionVWAP, 92.666_666_666_666_67, accuracy: 0.000_001)
    }

    private func candle(index: Int, high: Double, low: Double, close: Double) -> Candlestick {
        Candlestick(
            date: Date(timeIntervalSince1970: 1_704_067_200 + Double(index * 86_400)),
            open: close,
            high: high,
            low: low,
            close: close,
            volume: 1_000
        )
    }
}
