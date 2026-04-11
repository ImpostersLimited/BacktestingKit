import XCTest
@testable import BacktestingKit

final class BacktestingKitToolsTests: XCTestCase {
    func testValidationToolAcceptsStrictChronologicalCSV() {
        let csv = """
        timestamp,open,high,low,close,volume
        2024-01-01,1,2,0.5,1.5,100
        2024-01-02,1.5,2.5,1.0,2.0,120
        """

        let report = BKValidationTool.validateCSV(csv)
        XCTAssertTrue(report.isValid)
        XCTAssertEqual(report.issues.first?.code, "csv_ok")
    }

    func testValidationToolRejectsInvalidCSV() {
        let csv = """
        timestamp,open,high,low,close,volume
        2024-01-02,1,2,0.5,1.5,100
        2024-01-01,1.5,2.5,1.0,2.0,120
        """
        let report = BKValidationTool.validateCSV(csv)
        XCTAssertFalse(report.isValid)
        XCTAssertEqual(report.issues.first?.code, "csv_parse_error")
    }

    func testDiagnosticsCollectorRetainsBoundedEvents() async {
        let collector = BKDiagnosticsCollector(maxEvents: 2)
        await collector.emit(kind: .validationStarted, stage: "validation", message: "start")
        await collector.emit(kind: .parsingStarted, stage: "parsing", message: "parse start")
        await collector.emit(kind: .parsingCompleted, stage: "parsing", message: "parse done")
        let snapshot = await collector.snapshot()
        XCTAssertEqual(snapshot.count, 2)
        XCTAssertEqual(snapshot.first?.kind, .parsingStarted)
        XCTAssertEqual(snapshot.last?.kind, .parsingCompleted)
    }

    func testBenchmarkToolProducesStatistics() {
        let result = BKBenchmarkTool.run(name: "noop", iterations: 3, warmup: 1, measureMemory: false) {
            _ = 1 + 1
        }
        XCTAssertEqual(result.name, "noop")
        XCTAssertEqual(result.iterations, 3)
        XCTAssertEqual(result.samples.count, 3)
        XCTAssertGreaterThanOrEqual(result.maxMS, result.minMS)
    }

    func testParityToolDetectsMismatch() {
        let report = BKParityTool.compareMetrics(
            expected: ["profit": 10.0, "drawdown": -1.0],
            actual: ["profit": 10.2, "drawdown": -1.0],
            tolerance: 0.01
        )
        XCTAssertFalse(report.isMatch)
        XCTAssertEqual(report.comparedKeys, 2)
        XCTAssertEqual(report.mismatches.count, 1)
        XCTAssertEqual(report.mismatches.first?.key, "profit")
    }

    func testScenarioToolIsDeterministicBySeed() {
        let config = BKScenarioConfig(barCount: 50, seed: 123, strategy: .smaCrossover)
        let left = BKScenarioTool.run(config: config)
        let right = BKScenarioTool.run(config: config)
        XCTAssertEqual(left.candles.count, 50)
        XCTAssertEqual(left.candles, right.candles)
    }

    func testExportToolEncodesAndExportsTradesCSV() {
        let trade = BKTrade(
            direction: .long,
            entryTime: Date(timeIntervalSince1970: 0),
            entryPrice: 100,
            exitTime: Date(timeIntervalSince1970: 86_400),
            exitPrice: 110,
            profit: 10,
            profitPct: 10,
            growth: 1.1,
            holdingPeriod: 1,
            exitReason: "signal"
        )

        switch BKExportTool.tradesToCSV([trade]) {
        case .success(let csv):
            XCTAssertTrue(csv.localizedStandardContains("direction,entryTime"))
            XCTAssertTrue(csv.localizedStandardContains("long"))
        case .failure(let error):
            XCTFail("Expected CSV export success, got: \(error)")
        }

        switch BKExportTool.toJSON(BKValidationReport(isValid: true, issues: [])) {
        case .success(let json):
            XCTAssertTrue(json.localizedStandardContains("\"isValid\""))
        case .failure(let error):
            XCTFail("Expected JSON export success, got: \(error)")
        }
    }

    func testValidationToolBuildsStructuredPreflightReport() {
        let csv = """
        timestamp,open,high,low,close,volume
        2024-01-01,1,2,0.5,1.5,100
        2024-01-02,1.5,2.5,1.0,2.0,120
        """

        let report = BKValidationTool.preflightCSV(csv, symbol: "AAPL")
        XCTAssertTrue(report.isReady)
        XCTAssertEqual(report.symbol, "AAPL")
        XCTAssertEqual(report.rowCount, 2)
        XCTAssertEqual(report.startDate?.ISO8601Format(), "2024-01-01T00:00:00Z")
        XCTAssertEqual(report.endDate?.ISO8601Format(), "2024-01-02T00:00:00Z")
        XCTAssertEqual(report.validation.issues.first?.code, "csv_ok")
        XCTAssertEqual(report.diagnostics.count, 2)
        XCTAssertEqual(report.diagnostics.first?.kind, .validationStarted)
        XCTAssertEqual(report.diagnostics.last?.kind, .parsingCompleted)
    }

    func testDiagnosticsCollectorBuildsSummarizedSnapshot() async {
        let collector = BKDiagnosticsCollector(maxEvents: 10)
        await collector.emit(kind: .validationStarted, stage: "validation", message: "start")
        await collector.emit(kind: .simulationStarted, stage: "simulation", message: "running")
        await collector.emit(kind: .simulationFailed, stage: "simulation", message: "boom")

        let snapshot = await collector.summarizedSnapshot()
        XCTAssertEqual(snapshot.eventCount, 3)
        XCTAssertEqual(snapshot.stageCounts["validation"], 1)
        XCTAssertEqual(snapshot.stageCounts["simulation"], 2)
        XCTAssertEqual(snapshot.lastFailureEvent?.kind, .simulationFailed)
        XCTAssertNotNil(snapshot.firstTimestamp)
        XCTAssertNotNil(snapshot.lastTimestamp)
    }

    func testExportToolExportsStructuredPreflightBundle() {
        let report = BKToolPreflightReport(
            symbol: "AAPL",
            rowCount: 2,
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 86_400),
            validation: BKValidationReport(
                isValid: true,
                issues: [
                    BKValidationIssue(
                        code: "csv_ok",
                        field: "csv",
                        message: "CSV is valid (2 rows).",
                        severity: .info,
                        metadata: ["rowCount": "2"]
                    )
                ]
            ),
            diagnostics: [
                BKDiagnosticEvent(
                    timestamp: Date(timeIntervalSince1970: 0),
                    kind: .validationStarted,
                    stage: "validation",
                    message: "Starting CSV preflight."
                )
            ],
            isReady: true
        )
        let trade = BKTrade(
            direction: .long,
            entryTime: Date(timeIntervalSince1970: 0),
            entryPrice: 100,
            exitTime: Date(timeIntervalSince1970: 86_400),
            exitPrice: 110,
            profit: 10,
            profitPct: 10,
            growth: 1.1,
            holdingPeriod: 1,
            exitReason: "signal"
        )

        switch BKExportTool.exportPreflight(report, trades: [trade]) {
        case .success(let bundle):
            XCTAssertTrue(bundle.preflightJSON.localizedStandardContains("\"symbol\""))
            XCTAssertTrue(bundle.preflightJSON.localizedStandardContains("\"AAPL\""))
            XCTAssertTrue(bundle.diagnosticsJSON?.localizedStandardContains("\"validationStarted\"") == true)
            XCTAssertTrue(bundle.tradesCSV?.localizedStandardContains("direction,entryTime") == true)
        case .failure(let error):
            XCTFail("Expected structured preflight export success, got: \(error)")
        }
    }

    func testExportToolExportsRunBundle() {
        let summary = BKRunSummary(
            symbol: "AAPL",
            barCount: 10,
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 86_400),
            metrics: BKRunHeadlineMetrics(
                tradeCount: 2,
                winRate: 0.5,
                totalReturn: 0.12,
                annualizedReturn: 0.08,
                maxDrawdown: 0.03,
                sharpeRatio: 1.1,
                profitFactor: 1.8
            )
        )
        let diagnostics = BKDiagnosticsSnapshotReport(
            eventCount: 2,
            firstTimestamp: Date(timeIntervalSince1970: 0),
            lastTimestamp: Date(timeIntervalSince1970: 10),
            stageCounts: ["simulation": 2],
            lastFailureEvent: nil
        )
        let trade = BKTrade(
            direction: .long,
            entryTime: Date(timeIntervalSince1970: 0),
            entryPrice: 100,
            exitTime: Date(timeIntervalSince1970: 86_400),
            exitPrice: 110,
            profit: 10,
            profitPct: 10,
            growth: 1.1,
            holdingPeriod: 1,
            exitReason: "signal"
        )

        switch BKExportTool.exportRunBundle(
            summary: summary,
            trades: [trade],
            diagnostics: diagnostics,
            scenario: BKScenarioConfig(symbol: "AAPL")
        ) {
        case .success(let bundle):
            XCTAssertTrue(bundle.summaryJSON.localizedStandardContains("\"symbol\""))
            XCTAssertTrue(bundle.summaryJSON.localizedStandardContains("\"AAPL\""))
            XCTAssertTrue(bundle.diagnosticsSummaryJSON?.localizedStandardContains("\"eventCount\"") == true)
            XCTAssertTrue(bundle.tradesCSV?.localizedStandardContains("direction,entryTime") == true)
            XCTAssertTrue(bundle.scenarioJSON?.localizedStandardContains("\"strategy\"") == true)
        case .failure(let error):
            XCTFail("Expected run export success, got: \(error)")
        }
    }

    func testScenarioToolValidatesAndSummarizesConfig() {
        let invalid = BKScenarioTool.validate(
            config: BKScenarioConfig(symbol: "", barCount: 1, startingPrice: 0, volatility: -1)
        )
        XCTAssertFalse(invalid.isReady)
        XCTAssertEqual(invalid.validation.issues.count, 4)

        let validConfig = BKScenarioConfig(symbol: "SCENARIO", barCount: 20, seed: 7, strategy: .smaCrossover)
        let valid = BKScenarioTool.validate(config: validConfig)
        XCTAssertTrue(valid.isReady)

        let left = BKScenarioTool.summarize(config: validConfig)
        let right = BKScenarioTool.summarize(config: validConfig)
        XCTAssertEqual(left, right)
        XCTAssertEqual(left.symbol, "SCENARIO")
        XCTAssertEqual(left.barCount, 20)
    }

    func testScenarioToolExportsDeterministicRunBundle() {
        let config = BKScenarioConfig(symbol: "SCENARIO", barCount: 25, seed: 99, strategy: .emaFastSlow)
        let diagnostics = BKDiagnosticsSnapshotReport(eventCount: 0)

        let left = BKScenarioTool.runExportBundle(config: config, diagnostics: diagnostics)
        let right = BKScenarioTool.runExportBundle(config: config, diagnostics: diagnostics)

        switch (left, right) {
        case (.success(let lhs), .success(let rhs)):
            XCTAssertEqual(lhs, rhs)
            XCTAssertTrue(lhs.summaryJSON.localizedStandardContains("\"SCENARIO\""))
        default:
            XCTFail("Expected deterministic scenario export bundle success")
        }
    }

    func testComparisonToolDiffSummariesComputesFieldDeltas() {
        let baseline = BKRunSummary(
            symbol: "AAPL",
            barCount: 10,
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 86_400),
            metrics: BKRunHeadlineMetrics(
                tradeCount: 2,
                winRate: 0.5,
                totalReturn: 0.10,
                annualizedReturn: 0.12,
                maxDrawdown: 0.04,
                sharpeRatio: 1.0,
                profitFactor: 1.4
            )
        )
        let candidate = BKRunSummary(
            symbol: "AAPL",
            barCount: 12,
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 172_800),
            metrics: BKRunHeadlineMetrics(
                tradeCount: 3,
                winRate: 0.6,
                totalReturn: 0.15,
                annualizedReturn: 0.18,
                maxDrawdown: 0.03,
                sharpeRatio: 1.3,
                profitFactor: 1.8
            )
        )

        let diff = BKComparisonTool.diffSummaries(baseline: baseline, candidate: candidate)
        XCTAssertEqual(diff.barCountDelta, 2)
        XCTAssertFalse(diff.symbolChanged)
        XCTAssertTrue(diff.endDateChanged)
        XCTAssertEqual(diff.metrics.tradeCountDelta, 1)
        XCTAssertEqual(diff.metrics.totalReturnDelta, 0.05, accuracy: 0.000_001)
    }

    func testComparisonToolCompareRunsFlagsMaterialDifferences() {
        let baseline = BKRunSummary(
            symbol: "AAPL",
            barCount: 10,
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 86_400),
            metrics: BKRunHeadlineMetrics(
                tradeCount: 2,
                winRate: 0.5,
                totalReturn: 0.10,
                annualizedReturn: 0.12,
                maxDrawdown: 0.04,
                sharpeRatio: 1.0,
                profitFactor: 1.4
            )
        )
        let candidate = BKRunSummary(
            symbol: "AAPL",
            barCount: 10,
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 86_400),
            metrics: BKRunHeadlineMetrics(
                tradeCount: 2,
                winRate: 0.5000000001,
                totalReturn: 0.10,
                annualizedReturn: 0.12,
                maxDrawdown: 0.04,
                sharpeRatio: 1.25,
                profitFactor: 1.4
            )
        )

        let report = BKComparisonTool.compareRuns(
            baseline: baseline,
            candidate: candidate,
            tolerance: 0.001
        )

        XCTAssertFalse(report.isEquivalent)
        XCTAssertEqual(report.comparedFieldCount, 11)
        XCTAssertTrue(report.materiallyDifferentFields.contains("metrics.sharpeRatio"))
        XCTAssertFalse(report.materiallyDifferentFields.contains("metrics.winRate"))
    }

    func testComparisonToolAssertEquivalentReturnsReportForEquivalentRuns() throws {
        let summary = BKRunSummary(
            symbol: "AAPL",
            barCount: 10,
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 86_400),
            metrics: BKRunHeadlineMetrics(
                tradeCount: 2,
                winRate: 0.5,
                totalReturn: 0.1,
                annualizedReturn: 0.12,
                maxDrawdown: 0.04,
                sharpeRatio: 1.0,
                profitFactor: 1.4
            )
        )

        let report = try BKComparisonTool.assertEquivalent(
            baseline: summary,
            candidate: summary,
            tolerance: 0.000_001
        )

        XCTAssertTrue(report.isEquivalent)
        XCTAssertTrue(report.materiallyDifferentFields.isEmpty)
    }

    func testComparisonToolAssertEquivalentThrowsStructuredError() {
        let baseline = BKRunSummary(
            symbol: "AAPL",
            barCount: 10,
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 86_400),
            metrics: BKRunHeadlineMetrics(
                tradeCount: 2,
                winRate: 0.5,
                totalReturn: 0.1,
                annualizedReturn: 0.12,
                maxDrawdown: 0.04,
                sharpeRatio: 1.0,
                profitFactor: 1.4
            )
        )
        let candidate = BKRunSummary(
            symbol: "AAPL",
            barCount: 10,
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 86_400),
            metrics: BKRunHeadlineMetrics(
                tradeCount: 2,
                winRate: 0.5,
                totalReturn: 0.1,
                annualizedReturn: 0.12,
                maxDrawdown: 0.04,
                sharpeRatio: 1.25,
                profitFactor: 1.4
            )
        )

        XCTAssertThrowsError(
            try BKComparisonTool.assertEquivalent(
                baseline: baseline,
                candidate: candidate,
                tolerance: 0.001
            )
        ) { error in
            guard let assertion = error as? BKComparisonAssertionError else {
                XCTFail("Expected BKComparisonAssertionError, got \(error)")
                return
            }
            XCTAssertFalse(assertion.report.isEquivalent)
            XCTAssertTrue(assertion.report.materiallyDifferentFields.contains("metrics.sharpeRatio"))
        }
    }

    func testExportToolProducesMarkdownSummary() {
        let summary = BKRunSummary(
            symbol: "AAPL",
            barCount: 10,
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 86_400),
            metrics: BKRunHeadlineMetrics(
                tradeCount: 2,
                winRate: 0.5,
                totalReturn: 0.12,
                annualizedReturn: 0.08,
                maxDrawdown: 0.03,
                sharpeRatio: 1.1,
                profitFactor: 1.8
            )
        )

        switch BKExportTool.exportMarkdownSummary(summary, title: "Demo Summary") {
        case .success(let markdown):
            XCTAssertTrue(markdown.contains("# Demo Summary"))
            XCTAssertTrue(markdown.contains("- Symbol: `AAPL`"))
            XCTAssertTrue(markdown.contains("- Trades: 2"))
            XCTAssertTrue(markdown.contains("- Profit factor: 1.8000"))
        case .failure(let error):
            XCTFail("Expected Markdown export success, got \(error)")
        }
    }

    func testScenarioToolSmokeSuiteUsesValidDefaultMatrix() {
        let report = BKScenarioTool.smokeSuite()

        XCTAssertEqual(report.cases.count, 3)
        XCTAssertEqual(report.passedCaseCount, 3)
        XCTAssertEqual(report.failedCaseCount, 0)
        XCTAssertTrue(report.isSuccessful)
        XCTAssertEqual(report.cases.map(\.config.symbol), [
            "SCENARIO_SMA_BASE",
            "SCENARIO_EMA_TREND",
            "SCENARIO_SMA_VOL",
        ])
        XCTAssertTrue(report.cases.allSatisfy { $0.readiness.isReady && $0.summary != nil })
    }

    func testScenarioToolSmokeSuiteFlagsInvalidCases() {
        let configs = [
            BKScenarioConfig(symbol: "VALID", barCount: 10, seed: 1, strategy: .smaCrossover),
            BKScenarioConfig(symbol: "", barCount: 1, startingPrice: 0, volatility: -1, seed: 2, strategy: .emaFastSlow),
        ]

        let report = BKScenarioTool.smokeSuite(configs: configs)

        XCTAssertEqual(report.cases.count, 2)
        XCTAssertEqual(report.passedCaseCount, 1)
        XCTAssertEqual(report.failedCaseCount, 1)
        XCTAssertFalse(report.isSuccessful)
        XCTAssertNotNil(report.cases[0].summary)
        XCTAssertNil(report.cases[1].summary)
        XCTAssertFalse(report.cases[1].readiness.isReady)
    }
}
