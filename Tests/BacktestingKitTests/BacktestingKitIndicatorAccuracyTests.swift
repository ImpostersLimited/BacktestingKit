import XCTest
@testable import BacktestingKit

final class BacktestingKitIndicatorAccuracyTests: XCTestCase {
    func testDFSeriesEmaUsesRecursiveSmoothing() {
        let series = DFSeries(indices: Array(0..<5), values: [1.0, 2.0, 3.0, 4.0, 5.0])
        let ema = series.ema(3)

        XCTAssertEqual(ema.indices, [2, 3, 4])
        XCTAssertEqual(ema.values[0], 2.0, accuracy: 0.000_001)
        XCTAssertEqual(ema.values[1], 3.0, accuracy: 0.000_001)
        XCTAssertEqual(ema.values[2], 4.0, accuracy: 0.000_001)
    }

    func testDFSeriesRsiUsesWilderSmoothing() {
        let series = DFSeries(indices: Array(0..<8), values: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
        let rsi = series.rsi(3)

        XCTAssertEqual(rsi.indices, [3, 4, 5, 6, 7])
        XCTAssertTrue(rsi.values.allSatisfy { abs($0 - 100.0) < 0.000_001 })
    }

    func testStochasticFastAlignsPercentDToItsTrueStartIndex() {
        let bars = makeBars(count: 20)
        let frame = DFDataFrame(indices: Array(0..<bars.count), rows: bars)
        let stochFast = frame.stochasticFast(5, 3)

        guard let firstKRow = stochFast.indices.firstIndex(of: 4) else {
            XCTFail("Missing expected first stochastic %K index")
            return
        }
        XCTAssertNotNil(stochFast.rows[firstKRow]["percentK"])
        XCTAssertNil(stochFast.rows[firstKRow]["percentD"])
    }

    func testV2IndicatorEMAUsesRecursiveValues() {
        var rule = BKV2.SimulationRule()
        rule.indicatorOneName = "ema3"
        rule.indicatorOneType = .ema
        rule.indicatorOneFigure = [3, 0, 0]
        rule.indicatorTwoName = "close"
        rule.indicatorTwoType = .close
        rule.indicatorTwoFigure = [0, 0, 0]

        let bars = makeBars(count: 5).enumerated().map { index, bar in
            BKBar(
                time: bar.time,
                open: bar.open,
                high: bar.high,
                low: bar.low,
                close: Double(index + 1),
                volume: bar.volume
            )
        }

        let prepared = v2setTechnicalIndicators(bars, entryRules: [rule], exitRules: [])
        XCTAssertEqual(prepared.maxDays, 3)
        XCTAssertEqual(prepared.series.count, 2)
        guard let firstEma = prepared.series[0].indicators["ema3"],
              let secondEma = prepared.series[1].indicators["ema3"] else {
            XCTFail("Missing expected EMA values")
            return
        }
        XCTAssertEqual(firstEma, 3.0, accuracy: 0.000_001)
        XCTAssertEqual(secondEma, 4.0, accuracy: 0.000_001)
    }

    func testMoneyFlowIndexFlatSeriesReturnsNeutral50() {
        let candles = (0..<30).map { index in
            Candlestick(
                date: Date(timeIntervalSince1970: Double(index) * 86_400),
                open: 100,
                high: 101,
                low: 99,
                close: 100,
                adjustedClose: 100,
                volume: 1_000
            )
        }

        let manager = BacktestingKitManager()
        let result = manager.moneyFlowIndex(candles, period: 14, uuid: "flat")
        guard let mfi = result.last?.technicalIndicators["mfi_14_flat"] else {
            XCTFail("Missing MFI value")
            return
        }
        XCTAssertEqual(mfi, 50.0, accuracy: 0.000_001)
    }

    func testBollingerBandsPublishesShortAndAliasKeys() {
        let candles = (0..<40).map { index in
            let close = 100 + Double(index)
            return Candlestick(
                date: Date(timeIntervalSince1970: Double(index) * 86_400),
                open: close - 1,
                high: close + 1,
                low: close - 2,
                close: close,
                adjustedClose: close,
                volume: 1_000
            )
        }

        let manager = BacktestingKitManager()
        let result = manager.bollingerBands(candles, period: 20, numStdDev: 2.0, uuid: "alias")
        guard let last = result.last else {
            XCTFail("Missing bollinger output")
            return
        }

        XCTAssertNotNil(last.technicalIndicators["bbUpper_20_2.0_alias"])
        XCTAssertNotNil(last.technicalIndicators["bbMiddle_20_alias"])
        XCTAssertNotNil(last.technicalIndicators["bbLower_20_2.0_alias"])
        XCTAssertNotNil(last.technicalIndicators["bollingerUpper_20_2.0_alias"])
        XCTAssertNotNil(last.technicalIndicators["bollingerMiddle_20_alias"])
        XCTAssertNotNil(last.technicalIndicators["bollingerLower_20_2.0_alias"])
    }

    private func makeBars(count: Int) -> [BKBar] {
        (0..<count).map { index in
            let close = Double(index + (index % 3) + 1)
            return BKBar(
                time: Date(timeIntervalSince1970: Double(index) * 86_400),
                open: close - 0.5,
                high: close + 2.0,
                low: close - 2.0,
                close: close,
                volume: 1_000 + Double(index)
            )
        }
    }
}
