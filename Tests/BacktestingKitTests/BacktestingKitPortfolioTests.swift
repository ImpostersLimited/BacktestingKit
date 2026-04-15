import XCTest
@testable import BacktestingKit

final class BacktestingKitPortfolioTests: XCTestCase {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    func testRunPortfolioAggregatesExplicitSleeveWeights() {
        let growthSleeve = makeSleeve(
            symbol: "GROWTH",
            config: BKScenarioConfig(
                symbol: "GROWTH",
                barCount: 96,
                driftPerBar: 0.0010,
                volatility: 0.009,
                seed: 11,
                strategy: .smaCrossover
            )
        )
        let valueSleeve = makeSleeve(
            symbol: "VALUE",
            config: BKScenarioConfig(
                symbol: "VALUE",
                barCount: 96,
                driftPerBar: 0.0004,
                volatility: 0.014,
                seed: 22,
                strategy: .smaCrossover
            )
        )
        let individualRuns = [growthSleeve, valueSleeve].map { sleeve in
            BKEngine.preflightAndRunCSV(
                symbol: sleeve.symbol,
                csv: sleeve.csv,
                preset: sleeve.preset,
                dateFormat: sleeve.dateFormat,
                reverse: sleeve.reverse,
                columnMapping: sleeve.columnMapping
            )
        }

        let portfolio = BKEngine.runPortfolio(
            .init(
                portfolioID: "MODEL",
                sleeves: [growthSleeve, valueSleeve],
                allocation: .explicit([0.7, 0.3])
            )
        )

        XCTAssertTrue(portfolio.isSuccessful)
        XCTAssertFalse(portfolio.isPartialSuccess)
        XCTAssertEqual(portfolio.succeededSleeveCount, 2)
        XCTAssertEqual(portfolio.failedSleeveCount, 0)
        assertWeights(portfolio.sleeveReports.map(\.resolvedWeight), equal: [0.7, 0.3])

        guard let growthSummary = individualRuns[0].summary,
              let valueSummary = individualRuns[1].summary,
              let summary = portfolio.summary else {
            XCTFail("Expected successful sleeve and portfolio summaries")
            return
        }

        let expected = expectedMetrics(
            summaries: [growthSummary, valueSummary],
            weights: [0.7, 0.3]
        )

        XCTAssertEqual(summary.symbol, "MODEL")
        XCTAssertEqual(summary.barCount, growthSummary.barCount + valueSummary.barCount)
        XCTAssertEqual(summary.metrics.tradeCount, expected.tradeCount)
        XCTAssertEqual(summary.metrics.winRate, expected.winRate, accuracy: 1e-12)
        XCTAssertEqual(summary.metrics.totalReturn, expected.totalReturn, accuracy: 1e-12)
        XCTAssertEqual(summary.metrics.annualizedReturn, expected.annualizedReturn, accuracy: 1e-12)
        XCTAssertEqual(summary.metrics.maxDrawdown, expected.maxDrawdown, accuracy: 1e-12)
        XCTAssertEqual(summary.metrics.sharpeRatio, expected.sharpeRatio, accuracy: 1e-12)
        XCTAssertEqual(summary.metrics.profitFactor, expected.profitFactor, accuracy: 1e-12)
    }

    func testRunPortfolioRiskParityOverweightsLowerVolSleeve() {
        let lowVol = makeSleeve(
            symbol: "LOWVOL",
            config: BKScenarioConfig(
                symbol: "LOWVOL",
                barCount: 80,
                driftPerBar: 0.0005,
                volatility: 0.004,
                seed: 1,
                strategy: .smaCrossover
            )
        )
        let highVol = makeSleeve(
            symbol: "HIGHVOL",
            config: BKScenarioConfig(
                symbol: "HIGHVOL",
                barCount: 80,
                driftPerBar: 0.0005,
                volatility: 0.03,
                seed: 2,
                strategy: .smaCrossover
            )
        )

        let report = BKEngine.runPortfolio(
            .init(
                portfolioID: "RISK_PARITY",
                sleeves: [lowVol, highVol],
                allocation: .riskParity
            )
        )

        XCTAssertTrue(report.isSuccessful)
        XCTAssertEqual(report.sleeveReports.count, 2)
        let weights = report.sleeveReports.map(\.resolvedWeight)
        XCTAssertEqual(weights.reduce(0, +), 1.0, accuracy: 1e-12)
        XCTAssertGreaterThan(weights[0], weights[1])
        XCTAssertLessThan(
            report.sleeveReports[0].annualizedVolatility ?? .infinity,
            report.sleeveReports[1].annualizedVolatility ?? -.infinity
        )
    }

    func testRunPortfolioRiskOnRiskOffUsesMomentumPreset() {
        let riskOn = makeSleeve(
            symbol: "RISKON",
            config: BKScenarioConfig(
                symbol: "RISKON",
                barCount: 96,
                driftPerBar: 0.0012,
                volatility: 0.01,
                seed: 7,
                strategy: .smaCrossover
            )
        )
        let riskOff = makeSleeve(
            symbol: "RISKOFF",
            config: BKScenarioConfig(
                symbol: "RISKOFF",
                barCount: 96,
                driftPerBar: -0.0004,
                volatility: 0.006,
                seed: 8,
                strategy: .smaCrossover
            )
        )

        let report = BKEngine.runPortfolio(
            .init(
                portfolioID: "RISK_SWITCH",
                sleeves: [riskOn, riskOff],
                allocation: .riskOnRiskOff(riskOnIndex: 0, riskOffIndex: 1)
            )
        )

        XCTAssertTrue(report.isSuccessful)
        let riskOnMomentum = report.sleeveReports[0].momentumScore ?? 0
        let riskOffMomentum = report.sleeveReports[1].momentumScore ?? 0
        let expectedWeights = BKPortfolioPresets.riskOnRiskOffWeights(
            riskOnMomentum: riskOnMomentum,
            riskOffMomentum: riskOffMomentum
        )
        assertWeights(report.sleeveReports.map(\.resolvedWeight), equal: expectedWeights)
        XCTAssertEqual(report.sleeveReports.reduce(0) { $0 + $1.resolvedWeight }, 1.0, accuracy: 1e-12)
    }

    func testRunPortfolioBuildsPeriodicAndManualRebalanceEvents() {
        let sleeve = makeSleeve(
            symbol: "SLEEVE",
            config: BKScenarioConfig(
                symbol: "SLEEVE",
                barCount: 20,
                driftPerBar: 0.0008,
                volatility: 0.01,
                seed: 5,
                strategy: .smaCrossover
            )
        )

        let periodic = BKEngine.runPortfolio(
            .init(
                portfolioID: "PERIODIC",
                sleeves: [sleeve],
                allocation: .explicit([1.0]),
                rebalancePolicy: .periodic(.weekly)
            )
        )

        XCTAssertTrue(periodic.isSuccessful)
        XCTAssertEqual(periodic.rebalanceEvents.count, 2)
        XCTAssertEqual(periodic.rebalanceEvents.map(\.source), ["periodic:weekly", "periodic:weekly"])

        let manualDates = [
            Date(timeIntervalSince1970: 86_400 * 5),
            Date(timeIntervalSince1970: 86_400 * 40),
            Date(timeIntervalSince1970: 86_400 * 2),
        ]
        let manual = BKEngine.runPortfolio(
            .init(
                portfolioID: "MANUAL",
                sleeves: [sleeve],
                allocation: .explicit([1.0]),
                rebalancePolicy: .manual(manualDates)
            )
        )

        XCTAssertTrue(manual.isSuccessful)
        XCTAssertEqual(manual.rebalanceEvents.count, 2)
        XCTAssertEqual(manual.rebalanceEvents.map(\.source), ["manual", "manual"])
        XCTAssertEqual(
            manual.rebalanceEvents.map(\.date),
            [
                Date(timeIntervalSince1970: 86_400 * 2),
                Date(timeIntervalSince1970: 86_400 * 5),
            ]
        )
    }

    func testRunPortfolioRecordsPartialFailuresAndSupportsFailFastOverride() {
        let validOne = makeSleeve(
            symbol: "VALID_A",
            config: BKScenarioConfig(
                symbol: "VALID_A",
                barCount: 64,
                driftPerBar: 0.0009,
                volatility: 0.01,
                seed: 41,
                strategy: .smaCrossover
            )
        )
        let invalid = BKPortfolioSleeveRequest(
            symbol: "BROKEN",
            csv: "",
            preset: .smaCrossover
        )
        let validTwo = makeSleeve(
            symbol: "VALID_B",
            config: BKScenarioConfig(
                symbol: "VALID_B",
                barCount: 64,
                driftPerBar: 0.0003,
                volatility: 0.012,
                seed: 42,
                strategy: .smaCrossover
            )
        )

        let bestEffort = BKEngine.runPortfolio(
            .init(
                portfolioID: "BEST_EFFORT",
                sleeves: [validOne, invalid, validTwo],
                allocation: .explicit([0.4, 0.2, 0.4]),
                continueOnFailure: true
            )
        )

        XCTAssertTrue(bestEffort.isSuccessful)
        XCTAssertTrue(bestEffort.isPartialSuccess)
        XCTAssertEqual(bestEffort.succeededSleeveCount, 2)
        XCTAssertEqual(bestEffort.failedSleeveCount, 1)
        XCTAssertEqual(bestEffort.sleeveReports.count, 3)
        XCTAssertNotNil(bestEffort.summary)

        let failFast = BKEngine.runPortfolio(
            .init(
                portfolioID: "FAIL_FAST",
                sleeves: [validOne, invalid, validTwo],
                allocation: .explicit([0.4, 0.2, 0.4]),
                continueOnFailure: false
            )
        )

        XCTAssertTrue(failFast.isSuccessful)
        XCTAssertTrue(failFast.isPartialSuccess)
        XCTAssertEqual(failFast.succeededSleeveCount, 1)
        XCTAssertEqual(failFast.failedSleeveCount, 1)
        XCTAssertEqual(failFast.sleeveReports.count, 2)
    }

    func testRunPortfolioMarksAllocationValidationFailureAsUnsuccessful() {
        let first = makeSleeve(
            symbol: "FIRST",
            config: BKScenarioConfig(
                symbol: "FIRST",
                barCount: 64,
                driftPerBar: 0.0007,
                volatility: 0.01,
                seed: 101,
                strategy: .smaCrossover
            )
        )
        let second = makeSleeve(
            symbol: "SECOND",
            config: BKScenarioConfig(
                symbol: "SECOND",
                barCount: 64,
                driftPerBar: 0.0006,
                volatility: 0.012,
                seed: 202,
                strategy: .smaCrossover
            )
        )

        let report = BKEngine.runPortfolio(
            .init(
                portfolioID: "INVALID_ALLOC",
                sleeves: [first, second],
                allocation: .explicit([1.0])
            )
        )

        XCTAssertFalse(report.isSuccessful)
        XCTAssertTrue(report.isPartialSuccess)
        XCTAssertEqual(report.succeededSleeveCount, 2)
        XCTAssertEqual(report.failedSleeveCount, 0)
        XCTAssertNil(report.summary)
        XCTAssertTrue(report.failures.contains(where: { $0.stage == "portfolio-allocation" }))
    }

    func testRunPortfolioRejectsExplicitWeightsWhenSuccessfulSleevesResolveToNonPositiveTotal() {
        let first = makeSleeve(
            symbol: "FIRST",
            config: BKScenarioConfig(
                symbol: "FIRST",
                barCount: 64,
                driftPerBar: 0.0007,
                volatility: 0.01,
                seed: 101,
                strategy: .smaCrossover
            )
        )
        let second = makeSleeve(
            symbol: "SECOND",
            config: BKScenarioConfig(
                symbol: "SECOND",
                barCount: 64,
                driftPerBar: 0.0006,
                volatility: 0.012,
                seed: 202,
                strategy: .smaCrossover
            )
        )

        let report = BKEngine.runPortfolio(
            .init(
                portfolioID: "ZERO_TOTAL",
                sleeves: [first, second],
                allocation: .explicit([0, 0])
            )
        )

        XCTAssertFalse(report.isSuccessful)
        XCTAssertTrue(report.isPartialSuccess)
        XCTAssertEqual(report.succeededSleeveCount, 2)
        XCTAssertEqual(report.failedSleeveCount, 0)
        XCTAssertNil(report.summary)
        XCTAssertEqual(report.sleeveReports.map(\.resolvedWeight), [0, 0])
        XCTAssertTrue(report.failures.contains(where: {
            $0.stage == "portfolio-allocation"
                && $0.message.localizedStandardContains("positive total")
        }))
    }

    func testExportToolExportsPortfolioRunBundleAndMarkdownSummary() {
        let first = makeSleeve(
            symbol: "EXPORT_A",
            config: BKScenarioConfig(
                symbol: "EXPORT_A",
                barCount: 64,
                driftPerBar: 0.0007,
                volatility: 0.009,
                seed: 12,
                strategy: .smaCrossover
            )
        )
        let second = makeSleeve(
            symbol: "EXPORT_B",
            config: BKScenarioConfig(
                symbol: "EXPORT_B",
                barCount: 64,
                driftPerBar: 0.0002,
                volatility: 0.015,
                seed: 34,
                strategy: .smaCrossover
            )
        )
        let report = BKEngine.runPortfolio(
            .init(
                portfolioID: "EXPORTS",
                sleeves: [first, second],
                allocation: .explicit([0.6, 0.4]),
                rebalancePolicy: .periodic(.monthly)
            )
        )

        guard report.isSuccessful else {
            XCTFail("Expected successful portfolio report for export")
            return
        }

        switch BKExportTool.exportPortfolioRunBundle(report) {
        case .success(let bundle):
            XCTAssertTrue(bundle.portfolioJSON.localizedStandardContains("\"portfolioID\""))
            XCTAssertTrue(bundle.portfolioJSON.localizedStandardContains("\"EXPORTS\""))
            XCTAssertTrue(bundle.weightsCSV?.localizedStandardContains("symbol,preset,status") == true)
            XCTAssertTrue(bundle.weightsCSV?.localizedStandardContains("EXPORT_A") == true)
            XCTAssertNil(bundle.failuresJSON)
            XCTAssertTrue(bundle.rebalanceJSON?.localizedStandardContains("\"source\"") == true)
        case .failure(let error):
            XCTFail("Expected portfolio export success, got: \(error)")
        }

        switch BKExportTool.exportPortfolioMarkdownSummary(report, title: "Exports Summary") {
        case .success(let markdown):
            XCTAssertTrue(markdown.localizedStandardContains("# Exports Summary"))
            XCTAssertTrue(markdown.localizedStandardContains("`EXPORT_A`"))
            XCTAssertTrue(markdown.localizedStandardContains("## Sleeves"))
        case .failure(let error):
            XCTFail("Expected portfolio markdown export success, got: \(error)")
        }
    }

    private func makeSleeve(
        symbol: String,
        config: BKScenarioConfig,
        preset: BKPresetCatalog = .smaCrossover,
        targetWeight: Double? = nil
    ) -> BKPortfolioSleeveRequest {
        BKPortfolioSleeveRequest(
            symbol: symbol,
            csv: makeCSV(from: BKScenarioTool.generateCandles(config: config)),
            preset: preset,
            targetWeight: targetWeight
        )
    }

    private func makeCSV(from candles: [Candlestick]) -> String {
        let rows = candles.map { candle in
            [
                dateFormatter.string(from: candle.date),
                String(candle.open),
                String(candle.high),
                String(candle.low),
                String(candle.close),
                String(candle.volume),
            ].joined(separator: ",")
        }
        return (["timestamp,open,high,low,close,volume"] + rows).joined(separator: "\n")
    }

    private func expectedMetrics(
        summaries: [BKRunSummary],
        weights: [Double]
    ) -> BKRunHeadlineMetrics {
        let totalWeight = weights.reduce(0, +)
        let normalizedWeights = weights.map { totalWeight > 0 ? $0 / totalWeight : 0 }
        let totalTrades = summaries.reduce(0) { $0 + $1.metrics.tradeCount }
        let weightedWinRate: Double
        if totalTrades > 0 {
            weightedWinRate = zip(summaries, normalizedWeights).reduce(0) { partial, pair in
                partial + (Double(pair.0.metrics.tradeCount) * pair.0.metrics.winRate)
            } / Double(totalTrades)
        } else {
            weightedWinRate = zip(summaries, normalizedWeights).reduce(0) { partial, pair in
                partial + (pair.0.metrics.winRate * pair.1)
            }
        }

        func weighted(_ keyPath: KeyPath<BKRunHeadlineMetrics, Double>) -> Double {
            zip(summaries, normalizedWeights).reduce(0) { partial, pair in
                partial + (pair.0.metrics[keyPath: keyPath] * pair.1)
            }
        }

        return BKRunHeadlineMetrics(
            tradeCount: totalTrades,
            winRate: weightedWinRate,
            totalReturn: weighted(\.totalReturn),
            annualizedReturn: weighted(\.annualizedReturn),
            maxDrawdown: weighted(\.maxDrawdown),
            sharpeRatio: weighted(\.sharpeRatio),
            profitFactor: weighted(\.profitFactor)
        )
    }

    private func assertWeights(
        _ actual: [Double],
        equal expected: [Double],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual.count, expected.count, file: file, line: line)
        for (lhs, rhs) in zip(actual, expected) {
            XCTAssertEqual(lhs, rhs, accuracy: 1e-9, file: file, line: line)
        }
    }
}
