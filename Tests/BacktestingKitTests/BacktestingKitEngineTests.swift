import XCTest
@testable import BacktestingKit

final class BacktestingKitCSVTests: XCTestCase {
    func testCsvToBarsParsesIsoAndChronologicalData() {
        let csv = """
        timestamp,open,high,low,close,volume
        2024-01-01,1,2,0.5,1.5,100
        2024-01-02,1.5,2.5,1.0,2.0,120
        """
        guard case .success(let bars) = csvToBars(csv, reverse: false) else {
            XCTFail("Expected csvToBars success")
            return
        }

        XCTAssertEqual(bars.count, 2)
        XCTAssertEqual(bars.first?.open, 1)
        XCTAssertEqual(bars.last?.close, 2)
    }

    func testCsvToBarsRejectsNonChronologicalData() {
        let csv = """
        timestamp,open,high,low,close,volume
        2024-01-02,1,2,0.5,1.5,100
        2024-01-01,1.5,2.5,1.0,2.0,120
        """

        switch csvToBars(csv, reverse: false) {
        case .success:
            XCTFail("Expected nonChronologicalDate failure")
        case .failure(let error):
            guard case BKCSVParsingError.nonChronologicalDate = error else {
                XCTFail("Expected nonChronologicalDate, got \(error)")
                return
            }
        }
    }

    func testCsvToBarsSupportsCustomColumnMapping() {
        let csv = """
        Date,OpenPrice,HighPrice,LowPrice,ClosePrice,TradeVolume
        2024-01-01,1,2,0.5,1.5,100
        2024-01-02,1.5,2.5,1.0,2.0,120
        """
        let mapping = BKCSVColumnMapping(
            date: "Date",
            open: "OpenPrice",
            high: "HighPrice",
            low: "LowPrice",
            close: "ClosePrice",
            volume: "TradeVolume"
        )

        guard case .success(let bars) = csvToBars(csv, reverse: false, columnMapping: mapping) else {
            XCTFail("Expected csvToBars success with custom mapping")
            return
        }
        XCTAssertEqual(bars.count, 2)
        XCTAssertEqual(bars[0].high, 2)
        XCTAssertEqual(bars[1].volume, 120)
    }

    func testCsvToBarsParsesAdjustedCloseWhenAvailable() {
        let csv = """
        timestamp,open,high,low,close,adjusted_close,volume
        2024-01-01,1,2,0.5,1.5,1.45,100
        2024-01-02,1.5,2.5,1.0,2.0,1.95,120
        """

        guard case .success(let bars) = csvToBars(csv, reverse: false) else {
            XCTFail("Expected csvToBars success with adjusted close")
            return
        }
        XCTAssertEqual(bars.count, 2)
        XCTAssertEqual(bars[0].adjustedClose, 1.45)
        XCTAssertEqual(bars[1].adjustedClose, 1.95)
    }

    func testCsvToBarsSupportsAdjustedCloseCustomColumnMapping() {
        let csv = """
        Date,OpenPrice,HighPrice,LowPrice,ClosePrice,AdjPrice,TradeVolume
        2024-01-01,1,2,0.5,1.5,1.48,100
        2024-01-02,1.5,2.5,1.0,2.0,1.97,120
        """
        let mapping = BKCSVColumnMapping(
            date: "Date",
            open: "OpenPrice",
            high: "HighPrice",
            low: "LowPrice",
            close: "ClosePrice",
            adjustedClose: "AdjPrice",
            volume: "TradeVolume"
        )

        guard case .success(let bars) = csvToBars(csv, reverse: false, columnMapping: mapping) else {
            XCTFail("Expected csvToBars success with adjusted close mapping")
            return
        }
        XCTAssertEqual(bars.count, 2)
        XCTAssertEqual(bars[0].adjustedClose, 1.48)
        XCTAssertEqual(bars[1].adjustedClose, 1.97)
    }

    func testCsvToBarsStreamingStrictRejectsMalformedRows() {
        let csv = """
        timestamp,open,high,low,close,volume
        2024-01-01,1,2,0.5,1.5,100
        2024-01-02,1.5,2.5,1.0
        """

        switch csvToBarsStreaming(
            csv,
            reverse: false,
            strict: true
        ) {
        case .success:
            XCTFail("Expected malformedRow failure")
        case .failure(let error):
            guard case BKCSVParsingError.malformedRow = error else {
                XCTFail("Expected malformedRow, got \(error)")
                return
            }
        }
    }
}

final class BacktestingKitCandlestickTests: XCTestCase {
    func testCandlestickFromCSVParsesAdjustedCloseWhenPresent() {
        let csv = """
        date,open,high,low,close,volume,adjusted_close
        2024-01-01,1,2,0.5,1.5,100,1.45
        2024-01-02,1.5,2.5,1.0,2.0,120,1.95
        """

        let candles = Candlestick.fromCSV(csv)
        XCTAssertEqual(candles.count, 2)
        XCTAssertEqual(candles[0].adjustedClose, 1.45)
        XCTAssertEqual(candles[1].adjustedClose, 1.95)
    }
}

final class BacktestingKitOneLinerTests: XCTestCase {
    private struct InlineCsvProvider: BKRawCsvProvider {
        let csv: String

        func getRawCsv(ticker: String, p1: Double, p2: Double) async -> Result<String, Error> {
            .success(csv)
        }
    }

    private actor EmptyStore: BKV3DataStore {
        func getConfigs(instrumentID: String) async -> Result<[BKV3_Config], Error> { .success([]) }
        func getSimulationRules(configID: String, ruleType: String) async -> Result<[BKV3_SimulationRule], Error> { .success([]) }
        func saveConfig(_ config: BKV3_Config) async -> Result<Void, Error> { .success(()) }
        func saveAnalysis(_ analysis: BKV3_AnalysisProfile) async -> Result<Void, Error> { .success(()) }
        func saveTrades(_ trades: [BKV3_TradeEntry]) async -> Result<Void, Error> { .success(()) }
        func saveSimulationRules(_ rules: [BKV3_SimulationRule]) async -> Result<Void, Error> { .success(()) }
        func saveRisks(_ risks: [BKV3_RiskProfile]) async -> Result<Void, Error> { .success(()) }
    }

    private let inlineCsv = """
    timestamp,open,high,low,close,volume
    2024-01-01,10,11,9,10.5,100
    2024-01-02,10.5,11.5,10,11,120
    2024-01-03,11,12,10.8,11.8,140
    2024-01-04,11.8,12.2,11.3,12,130
    2024-01-05,12,12.4,11.9,12.2,125
    """

    func testOneLinerV2ReturnsSimulationOutput() async {
        var config = BKV2.SimulationPolicyConfig()
        config.policy = .sma
        config.entryRules = []
        config.exitRules = []

        let result = await BKEngine.runV2(
            .init(
                instrumentID: "AAPL",
                config: config,
                csvProvider: InlineCsvProvider(csv: inlineCsv)
            )
        )

        switch result {
        case .success(let payload):
            XCTAssertGreaterThanOrEqual(payload.0.config.t1, 0)
            let presentation = result.uiPresentation
            XCTAssertFalse(presentation.isError)
            XCTAssertEqual(presentation.metadata["status"], payload.1.rawValue)
        case .failure(let error):
            XCTFail("Expected success, got failure: \(error)")
        }
    }

    func testOneLinerV2ReturnsErrorForEmptyInstrument() async {
        let result = await BKEngine.runV2(
            .init(
                instrumentID: "   ",
                config: BKV2.SimulationPolicyConfig(),
                csvProvider: InlineCsvProvider(csv: inlineCsv)
            )
        )

        switch result {
        case .success:
            XCTFail("Expected failure for empty instrumentID")
        case .failure(let failure):
            XCTAssertEqual(failure.code, .invalidInput)
            XCTAssertEqual(failure.stage, "simulation-input")
            XCTAssertEqual(failure.instrumentID, "   ")
        }
    }

    func testOneLinerV3ReturnsReportWhenNoConfigs() async {
        let instrument = BKV3_InstrumentInfo(id: "AAPL", name: nil, exchange: nil, quoteType: nil, createdAt: nil, lastUpdated: nil)

        let result = await BKEngine.runV3(
            .init(
                instrument: instrument,
                dataStore: EmptyStore(),
                csvProvider: InlineCsvProvider(csv: inlineCsv)
            )
        )

        switch result {
        case .success(let report):
            XCTAssertEqual(report.instrumentID, "AAPL")
            XCTAssertEqual(report.configCountProcessed, 0)
            XCTAssertEqual(report.tradeCount, 0)
        case .failure(let error):
            XCTFail("Expected success, got failure: \(error)")
        }
    }

    func testOneLinerV3ReturnsTypedErrorForEmptyInstrument() async {
        let instrument = BKV3_InstrumentInfo(id: "   ", name: nil, exchange: nil, quoteType: nil, createdAt: nil, lastUpdated: nil)
        let result = await BKEngine.runV3(
            .init(
                instrument: instrument,
                dataStore: EmptyStore(),
                csvProvider: InlineCsvProvider(csv: inlineCsv)
            )
        )

        switch result {
        case .success:
            XCTFail("Expected failure for empty instrument ID")
        case .failure(let failure):
            XCTAssertEqual(failure.code, .invalidInput)
            XCTAssertEqual(failure.stage, "simulation-input")
            XCTAssertEqual(failure.instrumentID, "   ")
        }
    }

    func testResultUiPresentationProvidesStructuredData() async {
        let instrument = BKV3_InstrumentInfo(id: "   ", name: nil, exchange: nil, quoteType: nil, createdAt: nil, lastUpdated: nil)
        let result = await BKEngine.runV3(
            .init(
                instrument: instrument,
                dataStore: EmptyStore(),
                csvProvider: InlineCsvProvider(csv: inlineCsv)
            )
        )

        let presentation = result.uiPresentation
        XCTAssertTrue(presentation.isError)
        XCTAssertEqual(presentation.errorCode, BKEngineErrorCode.invalidInput.rawValue)
        XCTAssertFalse(presentation.title.isEmpty)
        XCTAssertFalse(presentation.summary.isEmpty)
    }
}

final class BacktestingKitDemoTests: XCTestCase {
    func testQuickDemoReturnsSummaryForBundledDataset() {
        switch BKQuickDemo.runBundledSMACrossoverDemo(dataset: .aapl, log: { _ in }) {
        case .success(let summary):
            XCTAssertEqual(summary.symbol, "AAPL")
            XCTAssertGreaterThan(summary.barCount, 1000)
            XCTAssertGreaterThanOrEqual(summary.result.numTrades, 0)
        case .failure(let error):
            XCTFail("Expected bundled demo success, got: \(error)")
        }
    }

    func testDemoResultUiPresentationSupportsErasedErrorType() {
        let result = BKEngine.runDemo(dataset: .aapl, csv: "")
        let presentation = result.uiPresentation
        XCTAssertTrue(presentation.isError)
        XCTAssertEqual(presentation.errorCode, "missing_header")
        XCTAssertFalse(presentation.summary.isEmpty)
    }

    // TODO: Add per-dataset snapshot validation when demo dataset baselines are finalized.
}

final class BacktestingKitMetricsTests: XCTestCase {
    func testBacktestComputesExtendedStrategyMetrics() {
        let dateFormatter = ISO8601DateFormatter()
        let closes: [Double] = [100, 110, 99, 120, 132]
        let candles: [Candlestick] = closes.enumerated().compactMap { index, close in
            guard let date = dateFormatter.date(from: "2024-01-0\(index + 1)T00:00:00Z") else {
                return nil
            }
            return Candlestick(
                date: date,
                open: close,
                high: close,
                low: close,
                close: close,
                adjustedClose: close,
                volume: 1_000
            )
        }

        XCTAssertEqual(candles.count, closes.count)

        let manager = BacktestingKitManager()
        let result = manager.backtest(
            candles: candles,
            uuid: "metrics-test",
            indicators: [],
            entrySignal: { _, curr in curr.index == 1 || curr.index == 3 },
            exitSignal: { _, curr, _ in curr.index == 2 || curr.index == 4 }
        )

        XCTAssertEqual(result.numTrades, 2)
        XCTAssertEqual(result.numWins, 1)
        XCTAssertEqual(result.numLosses, 1)
        XCTAssertEqual(result.avgHoldingPeriod, 1, accuracy: 0.000_001)
        XCTAssertEqual(result.maxConsecutiveWins, 1)
        XCTAssertEqual(result.maxConsecutiveLosses, 1)
        XCTAssertEqual(result.volatility, 0.141_421_356, accuracy: 0.000_001)
        XCTAssertEqual(result.profitFactor, 1, accuracy: 0.000_001)
        XCTAssertEqual(result.expectancy, 0, accuracy: 0.000_001)
        XCTAssertEqual(result.kellyCriterion, 0, accuracy: 0.000_001)
        XCTAssertGreaterThan(result.ulcerIndex, 0)
    }

    func testBuildMetricsReportProvidesDetailedBreakdown() {
        let dateFormatter = ISO8601DateFormatter()
        let closes: [Double] = [100, 110, 99, 120, 132]
        let candles: [Candlestick] = closes.enumerated().compactMap { index, close in
            guard let date = dateFormatter.date(from: "2024-01-0\(index + 1)T00:00:00Z") else {
                return nil
            }
            return Candlestick(
                date: date,
                open: close,
                high: close,
                low: close,
                close: close,
                adjustedClose: close,
                volume: 1_000
            )
        }

        let manager = BacktestingKitManager()
        let result = manager.backtest(
            candles: candles,
            uuid: "metrics-report-test",
            indicators: [],
            entrySignal: { _, curr in curr.index == 1 || curr.index == 3 },
            exitSignal: { _, curr, _ in curr.index == 2 || curr.index == 4 }
        )
        let report = manager.buildMetricsReport(from: result, candles: candles)

        XCTAssertEqual(report.result.numTrades, 2)
        XCTAssertEqual(report.tradeReturns.count, 2)
        XCTAssertEqual(report.additiveEquityCurve.count, 2)
        XCTAssertEqual(report.compoundedEquityCurve.count, 2)
        XCTAssertGreaterThanOrEqual(report.maxDrawdownPercent, 0)
        XCTAssertGreaterThanOrEqual(report.averageDrawdownPercent, 0)
        XCTAssertGreaterThanOrEqual(report.downsideDeviation, 0)
        XCTAssertEqual(report.payoffRatio, 1, accuracy: 0.000_001)
    }

    func testAdvancedIndicatorsAndMetricsSmoke() {
        let baseDate = Date(timeIntervalSince1970: 1_704_067_200) // 2024-01-01T00:00:00Z
        let candles: [Candlestick] = (0..<260).compactMap { idx in
            let close = 100 + Double(idx) * 0.2
            return Candlestick(
                date: baseDate.addingTimeInterval(Double(idx) * 86_400),
                open: close - 0.4,
                high: close + 0.8,
                low: close - 0.9,
                close: close,
                adjustedClose: close,
                volume: 1_000 + Double(idx)
            )
        }

        let manager = BacktestingKitManager()
        let atrBars = manager.averageTrueRange(candles, period: 14, uuid: "t")
        let adxBars = manager.adx(candles, period: 14, uuid: "t")
        let stochBars = manager.stochasticOscillator(candles, kPeriod: 14, dPeriod: 3, uuid: "t")
        let vwapBars = manager.vwap(candles, uuid: "t")
        let obvBars = manager.onBalanceVolume(candles, uuid: "t")
        let mfiBars = manager.moneyFlowIndex(candles, period: 14, uuid: "t")

        XCTAssertNotNil(atrBars.last?.technicalIndicators["atr_14_t"])
        XCTAssertNotNil(adxBars.last?.technicalIndicators["adx_14_t"])
        XCTAssertNotNil(stochBars.last?.technicalIndicators["stochK_14_t"])
        XCTAssertNotNil(vwapBars.last?.technicalIndicators["vwap_t"])
        XCTAssertNotNil(obvBars.last?.technicalIndicators["obv_t"])
        XCTAssertNotNil(mfiBars.last?.technicalIndicators["mfi_14_t"])

        let result = manager.backtestEMACrossover(candles: candles, fast: 5, slow: 20)
        let report = manager.buildMetricsReport(from: result, candles: candles)
        let advanced = manager.advancedPerformanceMetrics(report: report, candles: candles)

        XCTAssertGreaterThanOrEqual(advanced.exposurePercent, 0)
        XCTAssertGreaterThanOrEqual(advanced.timeUnderWaterPercent, 0)
        XCTAssertGreaterThanOrEqual(advanced.turnoverApprox, 0)
    }

    func testExecutionAdjustedTrades() {
        let trades = [
            Trade(
                type: .buy,
                entryDate: Date(timeIntervalSince1970: 0),
                entryPrice: 100,
                exitDate: Date(timeIntervalSince1970: 86_400),
                exitPrice: 110
            )
        ]
        let manager = BacktestingKitManager()
        let adjusted = manager.executionAdjustedTrades(
            trades: trades,
            quantity: 1,
            slippageModel: BKFixedBpsSlippageModel(bps: 10),
            commissionModel: BKFixedPlusPercentCommissionModel(fixedPerOrder: 1, percentOfNotional: 0.001)
        )
        XCTAssertEqual(adjusted.count, 1)
        XCTAssertLessThan(adjusted[0].netPnl, adjusted[0].grossPnl)
    }

    func testPresetStrategyExpansionsSmoke() {
        let baseDate = Date(timeIntervalSince1970: 1_704_067_200)
        let candles: [Candlestick] = (0..<320).map { idx in
            let wave = sin(Double(idx) / 8.0) * 2.0
            let close = 100 + Double(idx) * 0.08 + wave
            return Candlestick(
                date: baseDate.addingTimeInterval(Double(idx) * 86_400),
                open: close - 0.4,
                high: close + 1.0,
                low: close - 1.0,
                close: close,
                adjustedClose: close,
                volume: 1_000 + Double((idx % 20) * 100)
            )
        }

        let manager = BacktestingKitManager()

        XCTAssertGreaterThanOrEqual(manager.backtestDonchianBreakoutWithATRStop(candles: candles).numTrades, 0)
        XCTAssertGreaterThanOrEqual(manager.backtestSupertrend(candles: candles).numTrades, 0)
        XCTAssertGreaterThanOrEqual(manager.backtestDualEMAWithADXFilter(candles: candles).numTrades, 0)
        XCTAssertGreaterThanOrEqual(manager.backtestBollingerZScoreMeanReversion(candles: candles).numTrades, 0)
        XCTAssertGreaterThanOrEqual(manager.backtestRSI2MeanReversion(candles: candles).numTrades, 0)
        XCTAssertGreaterThanOrEqual(manager.backtestVWAPReversion(candles: candles).numTrades, 0)
        XCTAssertGreaterThanOrEqual(manager.backtestOBVTrendConfirmationBreakout(candles: candles).numTrades, 0)
        XCTAssertGreaterThanOrEqual(manager.backtestMFITrendFilterReversion(candles: candles).numTrades, 0)
        XCTAssertGreaterThanOrEqual(manager.backtestVolatilityContractionBreakout(candles: candles).numTrades, 0)

        let riskParity = BKPortfolioPresets.riskParityWeights(annualizedVolatilities: [0.1, 0.2, 0.3])
        XCTAssertEqual(riskParity.count, 3)
        XCTAssertEqual(riskParity.reduce(0, +), 1.0, accuracy: 0.000_001)
    }

    func testPresetCatalogCoversPolicyAndCandlePresets() {
        let policyCatalogItems = BKPresetCatalog.allCases.filter { $0.simulationPolicy != nil }
        XCTAssertEqual(policyCatalogItems.count, 13)

        for item in policyCatalogItems {
            let config = item.makeSimulationPolicyConfig()
            XCTAssertNotNil(config)
            if let policy = item.simulationPolicy, item != .customStrategy {
                XCTAssertEqual(config?.policy, policy)
            }
        }

        let baseDate = Date(timeIntervalSince1970: 1_704_067_200)
        let candles: [Candlestick] = (0..<320).map { idx in
            let wave = sin(Double(idx) / 8.0) * 2.0
            let close = 100 + Double(idx) * 0.08 + wave
            return Candlestick(
                date: baseDate.addingTimeInterval(Double(idx) * 86_400),
                open: close - 0.4,
                high: close + 1.0,
                low: close - 1.0,
                close: close,
                adjustedClose: close,
                volume: 1_000 + Double((idx % 20) * 100)
            )
        }
        let manager = BacktestingKitManager()
        let candleCatalogItems = BKPresetCatalog.allCases.filter { $0.family == "candle" }
        XCTAssertEqual(candleCatalogItems.count, 29)
        for item in candleCatalogItems {
            let result = item.runCandlePreset(with: manager, candles: candles)
            XCTAssertNotNil(result)
            XCTAssertGreaterThanOrEqual(result?.numTrades ?? -1, 0)
        }

        let fixedFractionalQty = BKPositionSizingPresetProfile.fixedFractional1Pct.sizingModel.quantity(
            price: 100,
            accountEquity: 100_000,
            annualizedVolatility: 0.20
        )
        let kellyQty = BKPositionSizingPresetProfile.kellyCapped30Pct.sizingModel.quantity(
            price: 100,
            accountEquity: 100_000,
            annualizedVolatility: 0.20
        )
        XCTAssertGreaterThan(fixedFractionalQty, 0)
        XCTAssertGreaterThan(kellyQty, 0)

        let rotation = BKPortfolioPresets.riskOnRiskOffWeights(riskOnMomentum: 0.12, riskOffMomentum: 0.03)
        XCTAssertEqual(rotation.count, 2)
        XCTAssertEqual(rotation.reduce(0, +), 1.0, accuracy: 0.000_001)
    }
}
