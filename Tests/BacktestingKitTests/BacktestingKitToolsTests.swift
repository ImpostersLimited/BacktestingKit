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
}
