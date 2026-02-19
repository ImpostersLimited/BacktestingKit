import XCTest
@testable import BacktestingKit

final class BacktestingKitShapeParityTests: XCTestCase {
    private func topLevelKeys<T: Encodable>(_ value: T) throws -> Set<String> {
        let data = try JSONEncoder().encode(value)
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = object as? [String: Any] else {
            XCTFail("Expected top-level JSON object for \(T.self)")
            return []
        }
        return Set(dictionary.keys)
    }

    func testBKEngineFailureJsonShapeRemainsStable() throws {
        let failure = BKEngineFailure(
            instrumentID: "AAPL",
            code: .simulation,
            stage: "simulate",
            message: "boom",
            isRetryable: true,
            timestamp: Date(timeIntervalSince1970: 0),
            metadata: ["k": "v"],
            recoverySuggestion: "retry"
        )

        let keys = try topLevelKeys(failure)
        XCTAssertEqual(
            keys,
            Set([
                "instrumentID",
                "code",
                "stage",
                "message",
                "isRetryable",
                "timestamp",
                "metadata",
                "recoverySuggestion",
            ])
        )
    }

    func testV2SimulateConfigOutputJsonShapeRemainsStable() throws {
        let output = BKV2.SimulateConfigOutput(
            analysis: BKV2.BKAnalysis(),
            trades: [],
            config: BKV2.SimulationPolicyConfig()
        )

        let keys = try topLevelKeys(output)
        XCTAssertEqual(keys, ["analysis", "trades", "config"])
    }

    func testV3InstrumentReportJsonShapeRemainsStable() throws {
        let report = BKSimulationInstrumentReport(
            instrumentID: "AAPL",
            elapsedMS: 12.3,
            configCountProcessed: 2,
            tradeCount: 10,
            riskPointCount: 4
        )

        let keys = try topLevelKeys(report)
        XCTAssertEqual(
            keys,
            Set([
                "instrumentID",
                "elapsedMS",
                "configCountProcessed",
                "tradeCount",
                "riskPointCount",
            ])
        )
    }

    func testV2EngineResultSuccessPayloadStaysTupleShaped() {
        let payload = (
            BKV2.SimulateConfigOutput(
                analysis: BKV2.BKAnalysis(),
                trades: [],
                config: BKV2.SimulationPolicyConfig()
            ),
            PositionStatus.none
        )

        let mirror = Mirror(reflecting: payload)
        let labels = mirror.children.compactMap(\.label)
        XCTAssertEqual(labels, [".0", ".1"])
    }
}
