import XCTest
@testable import BacktestingKit

final class BacktestingKitPresetRuleTests: XCTestCase {
    private struct InlineCSVProvider: BKRawCsvProvider {
        func getRawCsv(ticker: String, p1: Double, p2: Double) async -> Result<String, Error> {
            .success("""
            timestamp,open,high,low,close,volume
            2026-01-05,10,11,9,10,1000
            2026-01-06,11,12,10,11,1000
            2026-01-07,12,13,11,12,1000
            2026-01-08,13,14,12,13,1000
            """)
        }
    }

    private actor NamedRuleStore: BKV3DataStore {
        let config: BKV3_Config
        let rules: [BKV3_SimulationRule]
        var savedConfig: BKV3_Config?

        init(config: BKV3_Config, rules: [BKV3_SimulationRule]) {
            self.config = config
            self.rules = rules
        }

        func getConfigs(instrumentID: String) async -> Result<[BKV3_Config], Error> { .success([config]) }
        func getSimulationRules(configID: String, ruleType: String) async -> Result<[BKV3_SimulationRule], Error> {
            .success(rules.filter { $0.configId == configID && $0.ruleType?.rawValue == ruleType })
        }
        func saveConfig(_ config: BKV3_Config) async -> Result<Void, Error> {
            savedConfig = config
            return .success(())
        }
        func saveAnalysis(_ analysis: BKV3_AnalysisProfile) async -> Result<Void, Error> { .success(()) }
        func saveTrades(_ trades: [BKV3_TradeEntry]) async -> Result<Void, Error> { .success(()) }
        func saveSimulationRules(_ rules: [BKV3_SimulationRule]) async -> Result<Void, Error> { .success(()) }
        func saveRisks(_ risks: [BKV3_RiskProfile]) async -> Result<Void, Error> { .success(()) }
        func latestConfig() -> BKV3_Config? { savedConfig }
    }

    func testCorrectedPresetDefinitions() {
        let bollinger = bollingerPreset()
        XCTAssertEqual(bollinger.entryRules[0].compare, .largerOrEqualTo)

        let fastStochastic = stochasticFastPreset()
        XCTAssertEqual(fastStochastic.entryRules[0].indicatorTwoType, .stochasticFastPercentD)
        XCTAssertEqual(fastStochastic.exitRules[0].indicatorTwoType, .stochasticFastPercentD)

        for crossover in [smaCrossoverPreset(), emaCrossoverPreset()] {
            XCTAssertEqual(crossover.entryRules[0].compare, .largerOrEqualTo)
            XCTAssertEqual(crossover.exitRules[0].compare, .smallerOrEqualTo)
            XCTAssertEqual(crossover.entryRules[0].indicatorTwoFigure[0], 150)
            XCTAssertEqual(crossover.exitRules[0].indicatorTwoFigure[0], 150)
        }

        XCTAssertEqual(customPreset().policy, .customStrategy)
    }

    func testV3NamedPresetUsesSuppliedRulesWhenAvailable() async {
        let configID = "named-sma"
        let config = BKV3_Config(
            id: configID,
            active: true,
            createdAt: nil,
            instrumentId: "TEST",
            lastUpdated: nil,
            status: "pending",
            optimizeResultId: nil,
            policy: .sma,
            lastStatus: nil,
            trailingStopLoss: false,
            stopLossFigure: 15,
            profitFactor: 4_294_967_296,
            t1: 730,
            t2: -1
        )
        let entry = rule(
            configID: configID,
            type: .entry,
            lhsName: "entryClose",
            lhsType: .close,
            comparison: .largerThan,
            rhsName: "entryZero"
        )
        let exit = rule(
            configID: configID,
            type: .exit,
            lhsName: "exitClose",
            lhsType: .close,
            comparison: .smallThan,
            rhsName: "exitZero"
        )
        let store = NamedRuleStore(config: config, rules: [entry, exit])
        let driver = BKSimulationDriver(dataStore: store, csvProvider: InlineCSVProvider())

        let result = await driver.simulateInstrumentDetailed(BKV3_InstrumentInfo(
            id: "TEST",
            name: nil,
            exchange: nil,
            quoteType: nil,
            createdAt: nil,
            lastUpdated: nil
        ))

        guard case .success(let report) = result else {
            return XCTFail("Expected named canonical rules to simulate successfully")
        }
        let savedConfig = await store.latestConfig()
        XCTAssertEqual(report.configCountProcessed, 1)
        XCTAssertEqual(savedConfig?.lastStatus, .position)
    }

    private func rule(
        configID: String,
        type: RuleType,
        lhsName: String,
        lhsType: TechnicalIndicators,
        comparison: CompareOption,
        rhsName: String
    ) -> BKV3_SimulationRule {
        convertSimulationRule(
            SimulationRule(
                indicatorOneName: lhsName,
                indicatorOneType: lhsType,
                indicatorOneFigure: [0, 0, 0],
                compare: comparison,
                indicatorTwoName: rhsName,
                indicatorTwoType: .constant,
                indicatorTwoFigure: [0, 0, 0]
            ),
            type: type.rawValue,
            configID: configID,
            tickerID: "TEST"
        )
    }
}
