import XCTest
@testable import BacktestingKit

final class BacktestingKitManagerHelperTests: XCTestCase {
    private let inlineCsv = """
    timestamp,open,high,low,close,volume
    2024-01-01,100,101.5,99,100.75,1000
    2024-01-02,101,102.5,100,101.75,1010
    2024-01-03,102,103.5,101,102.75,1020
    2024-01-04,103,104.5,102,103.75,1030
    2024-01-05,104,105.5,103,104.75,1040
    2024-01-06,105,106.5,104,105.75,1050
    2024-01-07,106,107.5,105,106.75,1060
    2024-01-08,107,108.5,106,107.75,1070
    2024-01-09,108,109.5,107,108.75,1080
    2024-01-10,109,110.5,108,109.75,1090
    """

    private func makeCandles(count: Int = 40) -> [Candlestick] {
        let start = Date(timeIntervalSince1970: 1_704_067_200) // 2024-01-01
        return (0..<count).map { index in
            let base = 100.0 + Double(index)
            return Candlestick(
                date: Calendar.current.date(byAdding: .day, value: index, to: start) ?? start,
                open: base,
                high: base + 1.5,
                low: base - 1.0,
                close: base + 0.75,
                volume: 1_000 + Double(index * 10)
            )
        }
    }

    func testTrendIndicatorBundleAddsRequestedKeys() {
        let manager = BacktestingKitManager()
        let bundle = manager.applyTrendIndicatorBundle(
            candles: makeCandles(),
            smaPeriods: [5, 10],
            emaPeriods: [8],
            keyNamespace: "test"
        )

        XCTAssertEqual(bundle.appliedIndicatorKeys, ["sma_5_test", "sma_10_test", "ema_8_test_trend"])
        let last = bundle.candles.last?.technicalIndicators ?? [:]
        XCTAssertNotNil(last["sma_5_test"])
        XCTAssertNotNil(last["sma_10_test"])
        XCTAssertNotNil(last["ema_8_test_trend"])
    }

    func testMomentumIndicatorBundleAddsRequestedKeys() {
        let manager = BacktestingKitManager()
        let bundle = manager.applyMomentumIndicatorBundle(
            candles: makeCandles(),
            rsiPeriod: 6,
            stochasticKPeriod: 5,
            stochasticDPeriod: 3,
            keyNamespace: "test"
        )

        XCTAssertEqual(bundle.appliedIndicatorKeys, ["rsi_6_test_momentum_rsi", "stochK_5_test_momentum_stoch", "stochD_3_test_momentum_stoch"])
        let last = bundle.candles.last?.technicalIndicators ?? [:]
        XCTAssertNotNil(last["rsi_6_test_momentum_rsi"])
        XCTAssertNotNil(last["stochK_5_test_momentum_stoch"])
        XCTAssertNotNil(last["stochD_3_test_momentum_stoch"])
    }

    func testVolatilityIndicatorBundleAddsRequestedKeys() {
        let manager = BacktestingKitManager()
        let bundle = manager.applyVolatilityIndicatorBundle(
            candles: makeCandles(),
            atrPeriod: 5,
            bollingerPeriod: 6,
            bollingerStdDev: 2,
            keyNamespace: "test"
        )

        XCTAssertEqual(bundle.appliedIndicatorKeys, [
            "atr_5_test_volatility_atr",
            "bbMiddle_6_test_volatility_bb",
            "bbUpper_6_2.0_test_volatility_bb",
            "bbLower_6_2.0_test_volatility_bb"
        ])
        let last = bundle.candles.last?.technicalIndicators ?? [:]
        XCTAssertNotNil(last["atr_5_test_volatility_atr"])
        XCTAssertNotNil(last["bbMiddle_6_test_volatility_bb"])
        XCTAssertNotNil(last["bbUpper_6_2.0_test_volatility_bb"])
        XCTAssertNotNil(last["bbLower_6_2.0_test_volatility_bb"])
    }

    func testReportHelpersBuildSnapshotsAndAdvancedMetrics() {
        let manager = BacktestingKitManager()
        let candles = makeCandles()
        let result = manager.backtestSMACrossover(candles: candles, fast: 3, slow: 5)

        let snapshot = manager.buildReportSnapshot(from: result, candles: candles)
        XCTAssertEqual(snapshot.metrics.tradeCount, result.numTrades)

        let directReport = manager.buildMetricsReport(from: result, candles: candles)
        XCTAssertEqual(snapshot.tradeReturnCount, directReport.tradeReturns.count)

        let advanced = manager.buildAdvancedPerformanceMetrics(from: result, candles: candles)
        XCTAssertFalse(advanced.marRatio.isNaN)
        XCTAssertFalse(advanced.omegaRatio.isNaN)
    }

    func testRunStrategyRecipeMatchesUnderlyingSmaWorkflow() {
        let manager = BacktestingKitManager()
        let candles = makeCandles()

        let recipeResult = manager.runStrategyRecipe(.smaCrossover(fast: 3, slow: 5), candles: candles)
        let directResult = manager.backtestSMACrossover(candles: candles, fast: 3, slow: 5)

        XCTAssertEqual(recipeResult.numTrades, directResult.numTrades)
        XCTAssertEqual(recipeResult.totalReturn, directResult.totalReturn)
        XCTAssertEqual(recipeResult.maxDrawdown, directResult.maxDrawdown)
    }

    func testRunStrategyRecipeSummarySupportsRsiMeanReversionRecipe() {
        let manager = BacktestingKitManager()
        let candles = makeCandles(count: 260)

        let summary = manager.runStrategyRecipeSummary(
            .rsi2MeanReversion(trendPeriod: 50, entryThreshold: 12, exitThreshold: 55),
            symbol: "AAPL",
            candles: candles
        )

        XCTAssertEqual(summary.symbol, "AAPL")
        XCTAssertEqual(summary.barCount, candles.count)
        XCTAssertGreaterThanOrEqual(summary.metrics.tradeCount, 0)
    }

    func testParseAndRunRecipeParsesInlineCsvBeforeRunningRecipe() {
        let manager = BacktestingKitManager()

        switch manager.parseAndRunRecipe(
            .smaCrossover(fast: 3, slow: 5),
            csv: inlineCsv
        ) {
        case .success(let result):
            XCTAssertGreaterThanOrEqual(result.numTrades, 0)
            XCTAssertFalse(result.totalReturn.isNaN)
        case .failure(let error):
            XCTFail("Expected parseAndRunRecipe success, got \(error)")
        }
    }

    func testParseAndRunRecipePropagatesCsvFailure() {
        let manager = BacktestingKitManager()
        let invalidCsv = """
        timestamp,open,high,low,close,volume
        2024-01-02,101,102,100,101.5,1000
        2024-01-01,100,101,99,100.5,900
        """

        switch manager.parseAndRunRecipe(.smaCrossover(), csv: invalidCsv) {
        case .success:
            XCTFail("Expected parseAndRunRecipe failure for invalid CSV ordering")
        case .failure(let error):
            guard case BKCSVParsingError.nonChronologicalDate = error else {
                XCTFail("Expected nonChronologicalDate, got \(error)")
                return
            }
        }
    }

    func testRunRecipeReportPackagesSummarySnapshotAndAdvancedMetrics() {
        let manager = BacktestingKitManager()
        let candles = makeCandles(count: 260)

        let report = manager.runRecipeReport(
            .emaFastSlow(fastPeriod: 8, slowPeriod: 21, atrPeriod: 14, atrStopMultiplier: 2.5),
            symbol: "MSFT",
            candles: candles,
            minimumAcceptableReturn: 0.001
        )

        XCTAssertEqual(report.recipe, .emaFastSlow(fastPeriod: 8, slowPeriod: 21, atrPeriod: 14, atrStopMultiplier: 2.5))
        XCTAssertEqual(report.symbol, "MSFT")
        XCTAssertEqual(report.summary.symbol, "MSFT")
        XCTAssertEqual(report.summary.barCount, candles.count)
        XCTAssertEqual(report.snapshot.metrics.tradeCount, report.result.numTrades)
        XCTAssertFalse(report.advancedMetrics.omegaRatio.isNaN)
        XCTAssertFalse(report.advancedMetrics.marRatio.isNaN)
    }

    func testApplyDefaultScreeningBundleAddsFullCompositeKeySet() {
        let manager = BacktestingKitManager()
        let bundle = manager.applyDefaultScreeningBundle(candles: makeCandles(count: 260))

        XCTAssertEqual(bundle.appliedIndicatorKeys.count, 12)
        XCTAssertTrue(bundle.appliedIndicatorKeys.contains("sma_20_screening"))
        XCTAssertTrue(bundle.appliedIndicatorKeys.contains("sma_50_screening"))
        XCTAssertTrue(bundle.appliedIndicatorKeys.contains("sma_200_screening"))
        XCTAssertTrue(bundle.appliedIndicatorKeys.contains("ema_12_screening_trend"))
        XCTAssertTrue(bundle.appliedIndicatorKeys.contains("ema_26_screening_trend"))
        XCTAssertTrue(bundle.appliedIndicatorKeys.contains("rsi_14_screening_momentum_rsi"))
        XCTAssertTrue(bundle.appliedIndicatorKeys.contains("stochK_14_screening_momentum_stoch"))
        XCTAssertTrue(bundle.appliedIndicatorKeys.contains("stochD_3_screening_momentum_stoch"))
        XCTAssertTrue(bundle.appliedIndicatorKeys.contains("atr_14_screening_volatility_atr"))
        XCTAssertTrue(bundle.appliedIndicatorKeys.contains("bbMiddle_20_screening_volatility_bb"))
        XCTAssertTrue(bundle.appliedIndicatorKeys.contains("bbUpper_20_2.0_screening_volatility_bb"))
        XCTAssertTrue(bundle.appliedIndicatorKeys.contains("bbLower_20_2.0_screening_volatility_bb"))
    }
}
