import XCTest
@testable import BacktestingKit

final class BacktestingKitV3CanonicalRuleTests: XCTestCase {
    private actor RuleStore: BKV3DataStore {
        let configs: [BKV3_Config]
        let entryRule: BKV3_SimulationRule
        let exitRule: BKV3_SimulationRule
        private var requests: [String] = []
        private var savedTradeCount = 0

        init(configs: [BKV3_Config], entryRule: BKV3_SimulationRule, exitRule: BKV3_SimulationRule) {
            self.configs = configs
            self.entryRule = entryRule
            self.exitRule = exitRule
        }

        func getConfigs(instrumentID: String) async -> Result<[BKV3_Config], Error> {
            .success(configs)
        }

        func getSimulationRules(configID: String, ruleType: String) async -> Result<[BKV3_SimulationRule], Error> {
            requests.append("\(configID):\(ruleType)")
            return .success(ruleType == RuleType.entry.rawValue ? [entryRule] : [exitRule])
        }

        func saveConfig(_ config: BKV3_Config) async -> Result<Void, Error> { .success(()) }
        func saveAnalysis(_ analysis: BKV3_AnalysisProfile) async -> Result<Void, Error> { .success(()) }
        func saveTrades(_ trades: [BKV3_TradeEntry]) async -> Result<Void, Error> {
            savedTradeCount += trades.count
            return .success(())
        }
        func saveSimulationRules(_ rules: [BKV3_SimulationRule]) async -> Result<Void, Error> { .success(()) }
        func saveRisks(_ risks: [BKV3_RiskProfile]) async -> Result<Void, Error> { .success(()) }

        func snapshot() -> (requests: [String], savedTradeCount: Int) {
            (requests, savedTradeCount)
        }
    }

    func testEveryNamedV3PresetUsesSuppliedRules() async throws {
        let policies = BKPresetCatalog.allCases.compactMap(\.simulationPolicy).filter { $0 != .customStrategy }
        let configs = policies.map { policy in
            BKV3_Config(
                id: policy.rawValue,
                active: true,
                createdAt: nil,
                instrumentId: "TEST",
                lastUpdated: nil,
                status: nil,
                optimizeResultId: nil,
                policy: policy,
                lastStatus: nil,
                trailingStopLoss: false,
                stopLossFigure: 15,
                profitFactor: pow(2.0, 32.0),
                t1: 5,
                t2: 6
            )
        }
        let falseRule = SimulationRule(
            indicatorOneName: "alwaysFalseLeft",
            indicatorOneType: .constant,
            indicatorOneFigure: [0, 0, 0],
            compare: .largerThan,
            indicatorTwoName: "alwaysFalseRight",
            indicatorTwoType: .constant,
            indicatorTwoFigure: [1, 0, 0]
        )
        let store = RuleStore(
            configs: configs,
            entryRule: convertSimulationRule(falseRule, type: RuleType.entry.rawValue, configID: "shared", tickerID: "TEST"),
            exitRule: convertSimulationRule(falseRule, type: RuleType.exit.rawValue, configID: "shared", tickerID: "TEST")
        )
        let driver = BKSimulationDriver(
            dataStore: store,
            csvProvider: BKInlineCsvProvider(csv: makeCSV(rowCount: 220))
        )

        let result = await driver.simulateInstrumentDetailed(
            BKV3_InstrumentInfo(id: "TEST", name: nil, exchange: nil, quoteType: nil, createdAt: nil, lastUpdated: nil)
        )
        let report = try result.get()
        let snapshot = await store.snapshot()

        XCTAssertEqual(report.configCountProcessed, configs.count)
        XCTAssertEqual(snapshot.requests.count, configs.count * 2)
        let requestedRuleTypes = Set(snapshot.requests.compactMap { $0.split(separator: ":").last.map(String.init) })
        XCTAssertEqual(requestedRuleTypes, ["entry", "exit"])
        XCTAssertEqual(snapshot.savedTradeCount, 0)
    }

    private func makeCSV(rowCount: Int) -> String {
        let start = Date(timeIntervalSince1970: 1_704_067_200)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        let rows = (0..<rowCount).map { index -> String in
            let close = 100 + Double(index)
            let date = formatter.string(from: start.addingTimeInterval(Double(index) * 86_400))
            return "\(date),\(close),\(close + 1),\(close - 1),\(close),1000"
        }
        return (["timestamp,open,high,low,close,volume"] + rows).joined(separator: "\n")
    }
}
