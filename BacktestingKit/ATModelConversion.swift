import Foundation

private let isoFormatter = ISO8601DateFormatter()

private func isoString(_ date: Date) -> String {
    return isoFormatter.string(from: date)
}

public func convertSimulationRule(
    _ input: SimulationRule,
    type: String,
    configID: String,
    tickerID: String
) -> ATV3_SimulationRule {
    let ruleID = "\(configID)-\(type)-\(UUID().uuidString)"
    return ATV3_SimulationRule(
        id: ruleID,
        indicatorOneName: input.indicatorOneName,
        indicatorOneType: input.indicatorOneType.rawValue,
        indicatorOneFigureOne: input.indicatorOneFigure.count > 0 ? input.indicatorOneFigure[0] : 0,
        indicatorOneFigureTwo: input.indicatorOneFigure.count > 1 ? input.indicatorOneFigure[1] : 0,
        indicatorOneFigureThree: input.indicatorOneFigure.count > 2 ? input.indicatorOneFigure[2] : 0,
        compare: input.compare.rawValue,
        indicatorTwoName: input.indicatorTwoName,
        indicatorTwoType: input.indicatorTwoType.rawValue,
        indicatorTwoFigureOne: input.indicatorTwoFigure.count > 0 ? input.indicatorTwoFigure[0] : 0,
        indicatorTwoFigureTwo: input.indicatorTwoFigure.count > 1 ? input.indicatorTwoFigure[1] : 0,
        indicatorTwoFigureThree: input.indicatorTwoFigure.count > 2 ? input.indicatorTwoFigure[2] : 0,
        createdAt: Date(),
        lastUpdated: Date(),
        configId: configID,
        instrumentId: tickerID,
        ruleType: RuleType(rawValue: type)
    )
}

public func convertAnalysis(_ input: ATAnalysis, configID: String, tickerID: String) -> ATV3_AnalysisProfile {
    let analysisID = "\(configID)-analysis"
    return ATV3_AnalysisProfile(
        id: analysisID,
        startingCapital: input.startingCapital,
        finalCapital: input.finalCapital,
        profit: input.profit,
        profitPct: input.profitPct,
        growth: input.growth,
        totalTrades: Double(input.totalTrades),
        barCount: Double(input.barCount),
        maxDrawdown: input.maxDrawdown,
        maxDrawdownPct: input.maxDrawdownPct,
        maxRiskPct: input.maxRiskPct ?? 0,
        expectency: input.expectency,
        rmultipleStdDev: input.rmultipleStdDev,
        systemQuality: input.systemQuality ?? 0,
        profitFactor: input.profitFactor ?? 0,
        proportionProfitable: input.proportionProfitable,
        percentProfitable: input.percentProfitable,
        returnOnAccount: input.returnOnAccount,
        averageProfitPerTrade: input.averageProfitPerTrade,
        numWinningTrades: Double(input.numWinningTrades),
        numLosingTrades: Double(input.numLosingTrades),
        averageWinningTrade: input.averageWinningTrade,
        averageLosingTrade: input.averageLosingTrade,
        expectedValue: input.expectedValue,
        maxDownDrawNew: input.ATMaxDownDraw,
        maxDownDrawPctNew: input.ATMaxDownDrawPct,
        createdAt: Date(),
        lastUpdated: Date(),
        configId: configID,
        instrumentId: tickerID
    )
}

public func convertTradesWithRisks(_ trades: [ATTrade], configID: String, tickerID: String) -> ([ATV3_TradeEntry], [ATV3_RiskProfile]) {
    var riskProfiles: [ATV3_RiskProfile] = []
    var newTrades: [ATV3_TradeEntry] = []
    for trade in trades {
        let newTrade = convertTrade(trade, configID: configID, tickerID: tickerID)
        newTrades.append(newTrade)
        let stopRisks = convertRisks(trade.stopPriceSeries, riskType: "stop", tradeID: newTrade.id, configID: configID, tickerID: tickerID)
        let risks = convertRisks(trade.riskSeries, riskType: "risk", tradeID: newTrade.id, configID: configID, tickerID: tickerID)
        riskProfiles.append(contentsOf: stopRisks)
        riskProfiles.append(contentsOf: risks)
    }
    return (newTrades, riskProfiles)
}

public func convertTrade(_ input: ATTrade, configID: String, tickerID: String) -> ATV3_TradeEntry {
    let tradeID = "\(configID)-trade-\(isoString(input.entryTime))"
    return ATV3_TradeEntry(
        id: tradeID,
        direction: input.direction.rawValue,
        entryTime: isoString(input.entryTime),
        entryPrice: input.entryPrice,
        exitTime: isoString(input.exitTime),
        exitPrice: input.exitPrice,
        profit: input.profit,
        profitPct: input.profitPct,
        growth: input.growth,
        riskPct: input.riskPct,
        rmultiple: input.rmultiple,
        holdingPeriod: Double(input.holdingPeriod),
        exitReason: input.exitReason,
        stopPrice: input.stopPrice,
        profitTarget: input.profitTarget,
        configId: configID,
        lastUpdated: Date(),
        createdAt: Date(),
        instrumentId: tickerID
    )
}

public func convertRisk(_ input: ATTimestampedValue, riskType: String, tradeID: String, configID: String, tickerID: String) -> ATV3_RiskProfile {
    let id = "\(tradeID)-\(riskType)-\(isoString(input.time))"
    return ATV3_RiskProfile(
        id: id,
        seriesType: riskType,
        time: isoString(input.time),
        value: input.value,
        createdAt: Date(),
        lastUpdated: Date(),
        tradeEntryId: tradeID,
        instrumentId: tickerID,
        configId: configID
    )
}

public func convertRisks(_ risks: [ATTimestampedValue], riskType: String, tradeID: String, configID: String, tickerID: String) -> [ATV3_RiskProfile] {
    return risks.map { convertRisk($0, riskType: riskType, tradeID: tradeID, configID: configID, tickerID: tickerID) }
}
