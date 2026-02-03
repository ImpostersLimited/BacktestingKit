import Foundation

public struct V3SimulateConfigOutput: Codable, Equatable {
    public var analysis: ATAnalysis
    public var trades: [ATTrade]
    public var config: ATV3_Config

    public init(analysis: ATAnalysis, trades: [ATTrade], config: ATV3_Config) {
        self.analysis = analysis
        self.trades = trades
        self.config = config
    }
}

private func v3errorObj(config: ATV3_Config) -> (V3SimulateConfigOutput, PositionStatus) {
    let empty = V3SimulateConfigOutput(analysis: ATAnalysis(), trades: [], config: config)
    return (empty, .none)
}

public func v3simulateConfig(
    ticker: String,
    config: ATV3_Config,
    entryRules: [ATV3_SimulationRule],
    exitRules: [ATV3_SimulationRule],
    rawBars: [ATBar]
) -> (V3SimulateConfigOutput, PositionStatus) {
    if rawBars.count <= 1 {
        return v3errorObj(config: config)
    }

    let (inputSeries, maxDays) = v3setTechnicalIndicators(rawBars, entryRules: entryRules, exitRules: exitRules)
    if rawBars.count <= 1 || maxDays >= rawBars.count || inputSeries.isEmpty {
        return v3errorObj(config: config)
    }

    let checking = v3getCheckingFunction(entryRules: entryRules, exitRules: exitRules)
    guard let policy = config.policy else { return v3errorObj(config: config) }
    let strategy = getStrategy(
        policy: policy,
        riskPct: config.stopLossFigure ?? 0,
        entryFn: checking.0,
        exitFn: checking.1,
        trailingStopLoss: config.trailingStopLoss ?? false,
        profitFactor: config.profitFactor ?? Double.greatestFiniteMagnitude
    )

    let result = backtest(strategy: strategy, inputSeries: inputSeries, options: ATBacktestOptions(recordStopPrice: true, recordRisk: true))
    let analysis = analyze(startingCapital: 1_000_000, trades: result.trades)
    let realAnalysis = ATAnalysisTypeCheck(v3postAnalysis(analysis: analysis, trades: result.trades, config: config))
    let output = V3SimulateConfigOutput(analysis: realAnalysis, trades: result.trades, config: config)
    return (output, result.lastStatus)
}

public func simulate(
    ticker: String,
    config: ATV3_Config,
    entryRules: [ATV3_SimulationRule],
    exitRules: [ATV3_SimulationRule],
    rawBars: [ATBar]
) -> (V3SimulateConfigOutput, PositionStatus) {
    return v3simulateConfig(ticker: ticker, config: config, entryRules: entryRules, exitRules: exitRules, rawBars: rawBars)
}
