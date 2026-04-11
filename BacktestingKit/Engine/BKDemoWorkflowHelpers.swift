import Foundation

public extension BKQuickDemo {
    /// Runs a bundled dataset through a preset-backed workflow and returns a compact summary.
    @discardableResult
    static func runBundledPresetDemo(
        dataset: BKQuickDemoDataset,
        preset: BKPresetCatalog,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> Result<BKRunSummary, Error> {
        log("[Demo] Starting bundled preset demo for \(dataset.symbol) with \(preset.displayName).")

        let csv: String
        switch loadBundledCSV(dataset: dataset) {
        case .success(let bundledCSV):
            csv = bundledCSV
        case .failure(let error):
            return .failure(error)
        }

        let bars: [BKBar]
        switch parseBars(csv: csv, dateFormat: "yyyy-MM-dd", reverse: false) {
        case .success(let parsed):
            bars = parsed
        case .failure(let error):
            return .failure(error)
        }

        let candles = makeCandles(from: bars)
        return runPresetSummary(symbol: dataset.symbol, bars: bars, candles: candles, preset: preset)
    }

    /// Runs the same preset across a deterministic dataset matrix for smoke-test workflows.
    @discardableResult
    static func runBundledSmokeMatrix(
        datasets: [BKQuickDemoDataset] = BKQuickDemoDataset.allCases,
        preset: BKPresetCatalog = .smaCrossover,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> Result<[BKRunSummary], Error> {
        var summaries: [BKRunSummary] = []
        summaries.reserveCapacity(datasets.count)

        for dataset in datasets {
            switch runBundledPresetDemo(dataset: dataset, preset: preset, log: log) {
            case .success(let summary):
                summaries.append(summary)
            case .failure(let error):
                return .failure(error)
            }
        }

        return .success(summaries)
    }
}

extension BKQuickDemo {
    static func runPresetSummary(
        symbol: String,
        bars: [BKBar],
        candles: [Candlestick],
        preset: BKPresetCatalog
    ) -> Result<BKRunSummary, Error> {
        let manager = BacktestingKitManager()
        if let result = preset.runCandlePreset(with: manager, candles: candles) {
            return .success(summarize(symbol: symbol, bars: bars, result: result))
        }

        guard let config = preset.makeSimulationPolicyConfig() else {
            return .failure(BKQuickDemoError.unsupportedPreset(preset))
        }

        let v2Config = makeV2SimulationConfig(from: config)
        let output = v2simulateConfig(
            ticker: symbol,
            config: v2Config,
            entryRules: v2Config.entryRules,
            exitRules: v2Config.exitRules,
            rawBars: bars
        )

        return .success(
            BKRunSummary(
                symbol: symbol,
                barCount: bars.count,
                startDate: bars.first?.time,
                endDate: bars.last?.time,
                metrics: BKRunHeadlineMetrics(v2Analysis: output.0.analysis)
            )
        )
    }

    static func makeV2SimulationConfig(from config: SimulationPolicyConfig) -> BKV2.SimulationPolicyConfig {
        BKV2.SimulationPolicyConfig(
            policy: BKV2.SimulationPolicy(rawValue: config.policy.rawValue) ?? .custom,
            trailingStopLoss: config.trailingStopLoss,
            stopLossFigure: config.stopLossFigure,
            profitFactor: config.profitFactor,
            entryRules: makeV2SimulationRules(from: config.entryRules),
            exitRules: makeV2SimulationRules(from: config.exitRules),
            t1: config.t1,
            t2: config.t2
        )
    }

    static func makeV2SimulationRules(from rules: [SimulationRule]) -> [BKV2.SimulationRule] {
        rules.map { rule in
            BKV2.SimulationRule(
                indicatorOneName: rule.indicatorOneName,
                indicatorOneType: makeV2TechnicalIndicator(from: rule.indicatorOneType),
                indicatorOneFigure: rule.indicatorOneFigure.map { Int($0) },
                compare: makeV2CompareOption(from: rule.compare),
                indicatorTwoName: rule.indicatorTwoName,
                indicatorTwoType: makeV2TechnicalIndicator(from: rule.indicatorTwoType),
                indicatorTwoFigure: rule.indicatorTwoFigure.map { Int($0) }
            )
        }
    }

    static func makeV2TechnicalIndicator(from indicator: TechnicalIndicators) -> BKV2.TechnicalIndicators {
        BKV2.TechnicalIndicators(rawValue: indicator.rawValue) ?? .close
    }

    static func makeV2CompareOption(from compare: CompareOption) -> BKV2.CompareOption {
        BKV2.CompareOption(rawValue: compare.rawValue) ?? .equalTo
    }
}
