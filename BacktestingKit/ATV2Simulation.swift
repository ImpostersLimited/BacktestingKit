import Foundation

private func v2errorObj(config: ATV2.SimulationPolicyConfig) -> (ATV2.SimulateConfigOutput, PositionStatus) {
    let empty = ATV2.SimulateConfigOutput(analysis: ATV2.ATAnalysis(), trades: [], config: config)
    return (empty, .none)
}

public func v2simulateConfig(
    ticker: String,
    config: ATV2.SimulationPolicyConfig,
    entryRules: [ATV2.SimulationRule],
    exitRules: [ATV2.SimulationRule],
    rawBars: [ATBar]
) -> (ATV2.SimulateConfigOutput, PositionStatus) {
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

    let result = backtest(strategy: strategy, inputSeries: inputSeries, options: ATBacktestOptions(recordStopPrice: true, recordRisk: true))
    let analysis = analyze(startingCapital: 1_000_000, trades: result.trades)
    let realAnalysis = ATAnalysisTypeCheck(postAnalysis(analysis: analysis, trades: result.trades, config: config))
    let v2Trades = result.trades.map { convertTradeToV2($0) }
    let output = ATV2.SimulateConfigOutput(analysis: convertAnalysisToV2(realAnalysis), trades: v2Trades, config: config)
    return (output, result.lastStatus)
}

public func simulateV2(
    ticker: String,
    config: ATV2.SimulationPolicyConfig,
    entryRules: [ATV2.SimulationRule],
    exitRules: [ATV2.SimulationRule],
    rawBars: [ATBar]
) -> (ATV2.SimulateConfigOutput, PositionStatus) {
    return v2simulateConfig(ticker: ticker, config: config, entryRules: entryRules, exitRules: exitRules, rawBars: rawBars)
}

private func convertTradeToV2(_ trade: ATTrade) -> ATV2.ATTrade {
    let formatter = ISO8601DateFormatter()
    let entryTime = formatter.string(from: trade.entryTime)
    let exitTime = formatter.string(from: trade.exitTime)
    return ATV2.ATTrade(
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
        riskSeries: trade.riskSeries.map { ATV2.ATTimestampedValue(time: formatter.string(from: $0.time), value: $0.value) },
        holdingPeriod: Double(trade.holdingPeriod),
        exitReason: trade.exitReason,
        stopPrice: trade.stopPrice,
        stopPriceSeries: trade.stopPriceSeries.map { ATV2.ATTimestampedValue(time: formatter.string(from: $0.time), value: $0.value) },
        profitTarget: trade.profitTarget
    )
}

private func convertAnalysisToV2(_ analysis: ATAnalysis) -> ATV2.ATAnalysis {
    var v2 = ATV2.ATAnalysis()
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
    v2.ATMaxDownDraw = analysis.ATMaxDownDraw
    v2.ATMaxDownDrawPct = analysis.ATMaxDownDrawPct
    return v2
}

