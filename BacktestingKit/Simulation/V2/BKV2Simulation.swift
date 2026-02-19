import Foundation

private func v2errorObj(config: BKV2.SimulationPolicyConfig) -> (BKV2.SimulateConfigOutput, PositionStatus) {
    let empty = BKV2.SimulateConfigOutput(analysis: BKV2.BKAnalysis(), trades: [], config: config)
    return (empty, .none)
}

/// Executes `v2simulateConfig`.
public func v2simulateConfig(
    ticker: String,
    config: BKV2.SimulationPolicyConfig,
    entryRules: [BKV2.SimulationRule],
    exitRules: [BKV2.SimulationRule],
    rawBars: [BKBar]
) -> (BKV2.SimulateConfigOutput, PositionStatus) {
    if rawBars.count <= 1 {
        return v2errorObj(config: config)
    }

    let (inputSeries, maxDays) = v2setTechnicalIndicators(rawBars, entryRules: entryRules, exitRules: exitRules)
    if rawBars.count <= 1 || maxDays >= rawBars.count || inputSeries.isEmpty {
        return v2errorObj(config: config)
    }

    let checking = v2getCheckingFunction(config: config)
    let policy = SimulationPolicy(rawValue: config.policy.rawValue) ?? .sma
    let strategy = getStrategy(
        policy: policy,
        riskPct: config.stopLossFigure,
        entryFn: checking.0,
        exitFn: checking.1,
        trailingStopLoss: config.trailingStopLoss,
        profitFactor: config.profitFactor
    )

    let result = backtest(strategy: strategy, inputSeries: inputSeries, options: BKBacktestOptions(recordStopPrice: true, recordRisk: true))
    let analysis = analyze(startingCapital: 1_000_000, trades: result.trades)
    let realAnalysis = BKAnalysisTypeCheck(postAnalysis(analysis: analysis, trades: result.trades, config: config))
    let v2Trades = result.trades.map { convertTradeToV2($0) }
    let output = BKV2.SimulateConfigOutput(analysis: convertAnalysisToV2(realAnalysis), trades: v2Trades, config: config)
    return (output, result.lastStatus)
}

/// Executes `simulateV2`.
public func simulateV2(
    ticker: String,
    config: BKV2.SimulationPolicyConfig,
    entryRules: [BKV2.SimulationRule],
    exitRules: [BKV2.SimulationRule],
    rawBars: [BKBar]
) -> (BKV2.SimulateConfigOutput, PositionStatus) {
    return v2simulateConfig(ticker: ticker, config: config, entryRules: entryRules, exitRules: exitRules, rawBars: rawBars)
}

private func convertTradeToV2(_ trade: BKTrade) -> BKV2.BKTrade {
    let entryTime = trade.entryTime.ISO8601Format()
    let exitTime = trade.exitTime.ISO8601Format()
    return BKV2.BKTrade(
        direction: trade.direction == .long ? .long : .short,
        entryTime: entryTime,
        entryPrice: trade.entryPrice,
        exitTime: exitTime,
        exitPrice: trade.exitPrice,
        profit: trade.profit,
        profitPct: trade.profitPct,
        growth: trade.growth,
        riskPct: trade.riskPct,
        rmultiple: trade.rmultiple,
        riskSeries: trade.riskSeries.map { BKV2.BKTimestampedValue(time: $0.time.ISO8601Format(), value: $0.value) },
        holdingPeriod: Double(trade.holdingPeriod),
        exitReason: trade.exitReason,
        stopPrice: trade.stopPrice,
        stopPriceSeries: trade.stopPriceSeries.map { BKV2.BKTimestampedValue(time: $0.time.ISO8601Format(), value: $0.value) },
        profitTarget: trade.profitTarget
    )
}

private func convertAnalysisToV2(_ analysis: BKAnalysis) -> BKV2.BKAnalysis {
    var v2 = BKV2.BKAnalysis()
    v2.startingCapital = analysis.startingCapital
    v2.finalCapital = analysis.finalCapital
    v2.profit = analysis.profit
    v2.profitPct = analysis.profitPct
    v2.growth = analysis.growth
    v2.totalTrades = Double(analysis.totalTrades)
    v2.barCount = Double(analysis.barCount)
    v2.maxDrawdown = analysis.maxDrawdown
    v2.maxDrawdownPct = analysis.maxDrawdownPct
    v2.maxRiskPct = analysis.maxRiskPct
    v2.expectency = analysis.expectency
    v2.rmultipleStdDev = analysis.rmultipleStdDev
    v2.systemQuality = analysis.systemQuality
    v2.profitFactor = analysis.profitFactor
    v2.proportionProfitable = analysis.proportionProfitable
    v2.percentProfitable = analysis.percentProfitable
    v2.returnOnAccount = analysis.returnOnAccount
    v2.averageProfitPerTrade = analysis.averageProfitPerTrade
    v2.numWinningTrades = Double(analysis.numWinningTrades)
    v2.numLosingTrades = Double(analysis.numLosingTrades)
    v2.averageWinningTrade = analysis.averageWinningTrade
    v2.averageLosingTrade = analysis.averageLosingTrade
    v2.expectedValue = analysis.expectedValue
    v2.BKMaxDownDraw = analysis.BKMaxDownDraw
    v2.BKMaxDownDrawPct = analysis.BKMaxDownDrawPct
    return v2
}
