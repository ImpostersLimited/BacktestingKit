import XCTest
@testable import BacktestingKit

final class BacktestingKitDemoWorkflowTests: XCTestCase {
    func testBundledCSVHelpersLoadAndParseSampleDataset() throws {
        let csv: String
        switch BKQuickDemo.loadBundledCSV(dataset: .aapl) {
        case .success(let bundledCSV):
            csv = bundledCSV
        case .failure(let error):
            throw error
        }

        switch BKQuickDemo.parseBars(csv: csv) {
        case .success(let bars):
            XCTAssertFalse(bars.isEmpty)
            XCTAssertLessThan(bars.first!.time, bars.last!.time)
        case .failure(let error):
            XCTFail("Expected bundled CSV parse success, got: \(error)")
        }
    }

    func testBundledPresetDemoSupportsPolicyPresets() {
        switch BKQuickDemo.runBundledPresetDemo(dataset: .aapl, preset: .smaCrossover) {
        case .success(let summary):
            XCTAssertEqual(summary.symbol, "AAPL")
            XCTAssertGreaterThan(summary.barCount, 0)
        case .failure(let error):
            XCTFail("Expected policy preset demo success, got: \(error)")
        }
    }

    func testBundledPresetDemoSupportsCandlePresets() {
        switch BKQuickDemo.runBundledPresetDemo(dataset: .aapl, preset: .bollingerBandReversion) {
        case .success(let summary):
            XCTAssertEqual(summary.symbol, "AAPL")
            XCTAssertGreaterThan(summary.barCount, 0)
        case .failure(let error):
            XCTFail("Expected candle preset demo success, got: \(error)")
        }
    }

    func testBundledSmokeMatrixIsDeterministicForFixedDatasets() {
        let datasets: [BKQuickDemoDataset] = [.aapl, .msft]

        let left = BKQuickDemo.runBundledSmokeMatrix(datasets: datasets, preset: .smaCrossover)
        let right = BKQuickDemo.runBundledSmokeMatrix(datasets: datasets, preset: .smaCrossover)

        switch (left, right) {
        case (.success(let lhs), .success(let rhs)):
            XCTAssertEqual(lhs, rhs)
            XCTAssertEqual(lhs.map(\.symbol), ["AAPL", "MSFT"])
        case (.failure(let error), _), (_, .failure(let error)):
            XCTFail("Expected smoke matrix success, got: \(error)")
        }
    }
}
