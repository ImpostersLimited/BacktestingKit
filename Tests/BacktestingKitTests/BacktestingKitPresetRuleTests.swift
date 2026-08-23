import XCTest
@testable import BacktestingKit

final class BacktestingKitPresetRuleTests: XCTestCase {
    func testBollingerEntryRequiresCloseAtOrBelowLowerBand() {
        let config = bollingerPreset()
        XCTAssertEqual(config.entryRules[0].compare, .largerOrEqualTo)

        for checks in checkers(for: config) {
            XCTAssertFalse(checks.entry(args(close: 100, indicators: ["ruleOneEntryLower": 90])))
            XCTAssertTrue(checks.entry(args(close: 90, indicators: ["ruleOneEntryLower": 90])))
        }
    }

    func testFastStochasticUsesPercentKAgainstPercentD() {
        let config = stochasticFastPreset()
        XCTAssertEqual(config.entryRules[0].indicatorTwoType, .stochasticFastPercentD)
        XCTAssertEqual(config.exitRules[0].indicatorTwoType, .stochasticFastPercentD)

        let bullish = args(close: 100, indicators: [
            "ruleOneEntrypercentK": 80,
            "ruleOneExitpercentD": 70,
            "ruleTwoEntrypercentK": 80,
            "ruleTwoExitpercentD": 70
        ])
        let bearish = args(close: 100, indicators: [
            "ruleOneEntrypercentK": 60,
            "ruleOneExitpercentD": 70,
            "ruleTwoEntrypercentK": 60,
            "ruleTwoExitpercentD": 70
        ])

        for checks in checkers(for: config) {
            XCTAssertTrue(checks.entry(bullish))
            XCTAssertFalse(checks.exit(bullish))
            XCTAssertFalse(checks.entry(bearish))
            XCTAssertTrue(checks.exit(bearish))
        }
    }

    func testCustomPresetKeepsCustomPolicyIdentityAcrossV2AndV3() {
        let config = customPreset()
        XCTAssertEqual(config.policy, .customStrategy)
        XCTAssertEqual(BKQuickDemo.makeV2SimulationConfig(from: config).policy.rawValue, config.policy.rawValue)

        let v3Rule = convertSimulationRule(
            config.entryRules[0],
            type: RuleType.entry.rawValue,
            configID: "custom",
            tickerID: "TEST"
        )
        XCTAssertEqual(v3Rule.compare, config.entryRules[0].compare.rawValue)
    }

    func testMovingAveragePresetsUseActualBullishAndBearishCrossings() {
        for config in [smaCrossoverPreset(), emaCrossoverPreset()] {
            XCTAssertEqual(config.entryRules[0].compare, .largerOrEqualTo)
            XCTAssertEqual(config.exitRules[0].compare, .smallerOrEqualTo)
            XCTAssertEqual(config.entryRules[0].indicatorOneFigure[0], 50)
            XCTAssertEqual(config.entryRules[0].indicatorTwoFigure[0], 150)
            XCTAssertEqual(config.exitRules[0].indicatorOneFigure[0], 50)
            XCTAssertEqual(config.exitRules[0].indicatorTwoFigure[0], 150)

            for checks in checkers(for: config) {
                let strategy = getStrategy(
                    policy: config.policy,
                    riskPct: 100,
                    entryFn: checks.entry,
                    exitFn: checks.exit,
                    profitFactor: config.profitFactor
                )
                XCTAssertEqual(strategy.lookbackPeriod, 2)

                let noCross = backtest(
                    strategy: strategy,
                    inputSeries: [bar(0, 3, 2), bar(1, 4, 2), bar(2, 5, 2)]
                )
                XCTAssertTrue(noCross.trades.isEmpty)
                XCTAssertEqual(noCross.lastStatus, .none)

                let crossed = backtest(
                    strategy: strategy,
                    inputSeries: [
                        bar(0, 1, 2),
                        bar(1, 3, 2),
                        bar(2, 4, 2),
                        bar(3, 5, 2),
                        bar(4, 1, 2),
                        bar(5, 1, 2)
                    ]
                )
                XCTAssertEqual(crossed.trades.count, 1)
                XCTAssertEqual(crossed.trades[0].entryPrice, 102)
                XCTAssertEqual(crossed.trades[0].exitPrice, 105)
                XCTAssertEqual(crossed.lastStatus, .none)
            }
        }
    }

    private func checkers(for config: SimulationPolicyConfig) -> [(entry: BKCheckFn, exit: BKCheckFn)] {
        let v2Config = BKQuickDemo.makeV2SimulationConfig(from: config)
        let v2 = v2getCheckingFunction(config: v2Config)
        let v3 = v3getCheckingFunction(
            entryRules: config.entryRules.map {
                convertSimulationRule($0, type: RuleType.entry.rawValue, configID: "v3", tickerID: "TEST")
            },
            exitRules: config.exitRules.map {
                convertSimulationRule($0, type: RuleType.exit.rawValue, configID: "v3", tickerID: "TEST")
            }
        )
        return [(v2.0, v2.1), (v3.0, v3.1)]
    }

    private func args(close: Double, indicators: [String: Double]) -> BKRuleParams {
        let value = BKBar(
            time: Date(timeIntervalSince1970: 0),
            open: close,
            high: close,
            low: close,
            close: close,
            volume: 1,
            indicators: indicators
        )
        return BKRuleParams(bar: value, lookback: [value], parameters: [:])
    }

    private func bar(_ index: Int, _ fast: Double, _ slow: Double) -> BKBar {
        let open = 100 + Double(index)
        return BKBar(
            time: Date(timeIntervalSince1970: Double(index) * 86_400),
            open: open,
            high: open + 1,
            low: open - 1,
            close: open,
            volume: 1,
            indicators: [
                "ruleOneEntry": fast,
                "ruleOneExit": slow,
                "ruleTwoEntry": fast,
                "ruleTwoExit": slow
            ]
        )
    }
}
