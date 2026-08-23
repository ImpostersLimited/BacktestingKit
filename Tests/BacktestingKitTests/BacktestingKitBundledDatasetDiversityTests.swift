import Foundation
import XCTest
@testable import BacktestingKit

final class BacktestingKitBundledDatasetDiversityTests: XCTestCase {
    func testBundledDatasetsHaveDistinctReturnPathsAndMatchingCoverage() throws {
        var referenceDates: [Date]?
        var returnsByDataset: [(BKQuickDemoDataset, [Double])] = []

        for dataset in BKQuickDemoDataset.allCases {
            let csv: String
            switch BKQuickDemo.loadBundledCSV(dataset: dataset) {
            case .success(let value):
                csv = value
            case .failure(let error):
                throw error
            }

            let lines = csv.split(whereSeparator: \.isNewline)
            XCTAssertEqual(lines.first, "Date,Open,High,Low,Close,Volume", dataset.symbol)
            XCTAssertEqual(lines.count, 2_515, dataset.symbol)
            XCTAssertTrue(lines[1].hasPrefix("2016-02-19,"), dataset.symbol)
            XCTAssertTrue(lines[2_514].hasPrefix("2026-02-18,"), dataset.symbol)

            let bars: [BKBar]
            switch BKQuickDemo.parseBars(csv: csv) {
            case .success(let value):
                bars = value
            case .failure(let error):
                throw error
            }
            XCTAssertTrue(bars.allSatisfy {
                $0.open.isFinite && $0.high.isFinite && $0.low.isFinite && $0.close.isFinite
                    && $0.high >= max($0.open, $0.close)
                    && $0.low <= min($0.open, $0.close)
                    && $0.volume >= 0
            }, dataset.symbol)

            let dates = bars.map(\.time)
            if let referenceDates {
                XCTAssertEqual(dates, referenceDates, dataset.symbol)
            } else {
                referenceDates = dates
            }

            let returns = zip(bars, bars.dropFirst()).map { pair in
                pair.1.close / pair.0.close - 1
            }
            returnsByDataset.append((dataset, returns))
        }

        for leftIndex in returnsByDataset.indices {
            for rightIndex in returnsByDataset.indices where rightIndex > leftIndex {
                let left = returnsByDataset[leftIndex]
                let right = returnsByDataset[rightIndex]
                let pair = "\(left.0.symbol)/\(right.0.symbol)"
                let materiallyDifferentDays = zip(left.1, right.1).lazy
                    .filter { abs($0.0 - $0.1) > 0.0001 }
                    .count

                XCTAssertGreaterThan(materiallyDifferentDays, left.1.count / 4, pair)
                XCTAssertLessThan(abs(correlation(left.1, right.1)), 0.995, pair)
            }
        }
    }

    private func correlation(_ lhs: [Double], _ rhs: [Double]) -> Double {
        let leftMean = lhs.reduce(0, +) / Double(lhs.count)
        let rightMean = rhs.reduce(0, +) / Double(rhs.count)
        let numerator = zip(lhs, rhs).reduce(0) {
            $0 + ($1.0 - leftMean) * ($1.1 - rightMean)
        }
        let leftVariance = lhs.reduce(0) { $0 + pow($1 - leftMean, 2) }
        let rightVariance = rhs.reduce(0) { $0 + pow($1 - rightMean, 2) }
        return numerator / sqrt(leftVariance * rightVariance)
    }
}
