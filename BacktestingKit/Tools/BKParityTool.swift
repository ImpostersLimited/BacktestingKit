import Foundation

/// A single mismatch discovered during parity comparison.
public struct BKParityMismatch: Codable, Equatable {
    /// Metric key that diverged.
    public var key: String
    /// Baseline value.
    public var expected: Double
    /// Candidate value.
    public var actual: Double
    /// Absolute delta (`abs(expected-actual)`).
    public var absoluteDelta: Double
    /// Effective tolerance threshold.
    public var tolerance: Double

    /// Creates a mismatch value.
    public init(key: String, expected: Double, actual: Double, absoluteDelta: Double, tolerance: Double) {
        self.key = key
        self.expected = expected
        self.actual = actual
        self.absoluteDelta = absoluteDelta
        self.tolerance = tolerance
    }
}

/// Result summary from a parity comparison run.
public struct BKParityReport: Codable, Equatable {
    /// True when there are no missing keys or mismatches above tolerance.
    public var isMatch: Bool
    /// Number of shared keys compared.
    public var comparedKeys: Int
    /// Expected keys that were absent in candidate payload.
    public var missingKeys: [String]
    /// Detailed mismatch list.
    public var mismatches: [BKParityMismatch]

    /// Creates a parity report.
    public init(
        isMatch: Bool,
        comparedKeys: Int,
        missingKeys: [String],
        mismatches: [BKParityMismatch]
    ) {
        self.isMatch = isMatch
        self.comparedKeys = comparedKeys
        self.missingKeys = missingKeys
        self.mismatches = mismatches
    }
}

/// Numeric parity utilities to compare expected vs actual metric payloads.
public enum BKParityTool {
    /// Compares two flat metric dictionaries with numeric tolerance.
    ///
    /// - Parameters:
    ///   - expected: Baseline metric map.
    ///   - actual: Candidate metric map.
    ///   - tolerance: Allowed absolute numeric delta.
    /// - Returns: Structured parity report.
    public static func compareMetrics(
        expected: [String: Double],
        actual: [String: Double],
        tolerance: Double = 1e-8
    ) -> BKParityReport {
        let toleranceValue = max(0, tolerance)
        let expectedKeys = Set(expected.keys)
        let actualKeys = Set(actual.keys)
        let sharedKeys = expectedKeys.intersection(actualKeys).sorted()
        let missingKeys = expectedKeys.subtracting(actualKeys).sorted()

        var mismatches: [BKParityMismatch] = []
        mismatches.reserveCapacity(sharedKeys.count)
        for key in sharedKeys {
            guard let left = expected[key], let right = actual[key] else { continue }
            let delta = abs(left - right)
            if delta > toleranceValue {
                mismatches.append(
                    BKParityMismatch(
                        key: key,
                        expected: left,
                        actual: right,
                        absoluteDelta: delta,
                        tolerance: toleranceValue
                    )
                )
            }
        }

        return BKParityReport(
            isMatch: missingKeys.isEmpty && mismatches.isEmpty,
            comparedKeys: sharedKeys.count,
            missingKeys: missingKeys,
            mismatches: mismatches
        )
    }

    /// Compares two strategy analysis payloads by canonical numeric fields.
    ///
    /// - Parameters:
    ///   - expected: Baseline analysis payload.
    ///   - actual: Candidate analysis payload.
    ///   - tolerance: Allowed absolute numeric delta.
    /// - Returns: Structured parity report.
    public static func compareAnalysis(
        expected: BKAnalysis,
        actual: BKAnalysis,
        tolerance: Double = 1e-8
    ) -> BKParityReport {
        compareMetrics(
            expected: [
                "profit": expected.profit,
                "profitPct": expected.profitPct,
                "growth": expected.growth,
                "maxDrawdown": expected.maxDrawdown,
                "maxDrawdownPct": expected.maxDrawdownPct,
                "expectency": expected.expectency,
                "rmultipleStdDev": expected.rmultipleStdDev,
                "systemQuality": expected.systemQuality ?? 0,
                "profitFactor": expected.profitFactor ?? 0,
                "proportionProfitable": expected.proportionProfitable,
                "returnOnAccount": expected.returnOnAccount,
                "averageProfitPerTrade": expected.averageProfitPerTrade,
                "averageWinningTrade": expected.averageWinningTrade,
                "averageLosingTrade": expected.averageLosingTrade,
                "expectedValue": expected.expectedValue,
                "BKMaxDownDraw": expected.BKMaxDownDraw,
                "BKMaxDownDrawPct": expected.BKMaxDownDrawPct,
            ],
            actual: [
                "profit": actual.profit,
                "profitPct": actual.profitPct,
                "growth": actual.growth,
                "maxDrawdown": actual.maxDrawdown,
                "maxDrawdownPct": actual.maxDrawdownPct,
                "expectency": actual.expectency,
                "rmultipleStdDev": actual.rmultipleStdDev,
                "systemQuality": actual.systemQuality ?? 0,
                "profitFactor": actual.profitFactor ?? 0,
                "proportionProfitable": actual.proportionProfitable,
                "returnOnAccount": actual.returnOnAccount,
                "averageProfitPerTrade": actual.averageProfitPerTrade,
                "averageWinningTrade": actual.averageWinningTrade,
                "averageLosingTrade": actual.averageLosingTrade,
                "expectedValue": actual.expectedValue,
                "BKMaxDownDraw": actual.BKMaxDownDraw,
                "BKMaxDownDrawPct": actual.BKMaxDownDrawPct,
            ],
            tolerance: tolerance
        )
    }
}
