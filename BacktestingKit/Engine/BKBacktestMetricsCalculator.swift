import Foundation

protocol BKBacktestMetricsCalculating {
    func emptyResult() -> BacktestResult
    func makeResult(trades: [Trade], candles: [Candlestick]) -> BacktestResult
    func makeReport(trades: [Trade], candles: [Candlestick]) -> BacktestMetricsReport
}

struct BKComputedBacktestMetrics {
    let trades: [Trade]
    let tradeReturns: [Double]
    let additiveEquityCurve: [Double]
    let compoundedEquityCurve: [Double]
    let totalReturn: Double
    let annualizedReturn: Double
    let winRate: Double
    let maxDrawdown: Double
    let maxDrawdownPercent: Double
    let averageDrawdownPercent: Double
    let sharpeRatio: Double
    let avgTradeReturn: Double
    let numTrades: Int
    let numWins: Int
    let numLosses: Int
    let profitFactor: Double
    let expectancy: Double
    let cagr: Double
    let volatility: Double
    let downsideDeviation: Double
    let sortinoRatio: Double
    let calmarRatio: Double
    let avgHoldingPeriod: Double
    let maxConsecutiveWins: Int
    let maxConsecutiveLosses: Int
    let avgWin: Double
    let avgLoss: Double
    let kellyCriterion: Double
    let ulcerIndex: Double
    let totalCompoundedReturn: Double
    let payoffRatio: Double
    let recoveryFactor: Double
}

final class BKBacktestMetricsCalculator: BKBacktestMetricsCalculating {
    func emptyResult() -> BacktestResult {
        BacktestResult(
            trades: [],
            totalReturn: 0,
            annualizedReturn: 0,
            winRate: 0,
            maxDrawdown: 0,
            sharpeRatio: 0,
            avgTradeReturn: 0,
            numTrades: 0,
            numWins: 0,
            numLosses: 0,
            profitFactor: 0,
            expectancy: 0,
            cagr: 0,
            volatility: 0,
            sortinoRatio: 0,
            calmarRatio: 0,
            avgHoldingPeriod: 0,
            maxConsecutiveWins: 0,
            maxConsecutiveLosses: 0,
            avgWin: 0,
            avgLoss: 0,
            kellyCriterion: 0,
            ulcerIndex: 0
        )
    }

    func makeResult(trades: [Trade], candles: [Candlestick]) -> BacktestResult {
        guard let metrics = compute(trades: trades, candles: candles) else {
            return emptyResult()
        }

        return BacktestResult(
            trades: metrics.trades,
            totalReturn: metrics.totalReturn,
            annualizedReturn: metrics.annualizedReturn,
            winRate: metrics.winRate,
            maxDrawdown: metrics.maxDrawdown,
            sharpeRatio: metrics.sharpeRatio,
            avgTradeReturn: metrics.avgTradeReturn,
            numTrades: metrics.numTrades,
            numWins: metrics.numWins,
            numLosses: metrics.numLosses,
            profitFactor: metrics.profitFactor,
            expectancy: metrics.expectancy,
            cagr: metrics.cagr,
            volatility: metrics.volatility,
            sortinoRatio: metrics.sortinoRatio,
            calmarRatio: metrics.calmarRatio,
            avgHoldingPeriod: metrics.avgHoldingPeriod,
            maxConsecutiveWins: metrics.maxConsecutiveWins,
            maxConsecutiveLosses: metrics.maxConsecutiveLosses,
            avgWin: metrics.avgWin,
            avgLoss: metrics.avgLoss,
            kellyCriterion: metrics.kellyCriterion,
            ulcerIndex: metrics.ulcerIndex
        )
    }

    func makeReport(trades: [Trade], candles: [Candlestick]) -> BacktestMetricsReport {
        guard let metrics = compute(trades: trades, candles: candles) else {
            let empty = emptyResult()
            return BacktestMetricsReport(
                result: empty,
                totalCompoundedReturn: 0,
                maxDrawdownPercent: 0,
                averageDrawdownPercent: 0,
                downsideDeviation: 0,
                payoffRatio: 0,
                recoveryFactor: 0,
                tradeReturns: [],
                additiveEquityCurve: [],
                compoundedEquityCurve: []
            )
        }

        let result = makeResult(trades: trades, candles: candles)
        return BacktestMetricsReport(
            result: result,
            totalCompoundedReturn: metrics.totalCompoundedReturn,
            maxDrawdownPercent: metrics.maxDrawdownPercent,
            averageDrawdownPercent: metrics.averageDrawdownPercent,
            downsideDeviation: metrics.downsideDeviation,
            payoffRatio: metrics.payoffRatio,
            recoveryFactor: metrics.recoveryFactor,
            tradeReturns: metrics.tradeReturns,
            additiveEquityCurve: metrics.additiveEquityCurve,
            compoundedEquityCurve: metrics.compoundedEquityCurve
        )
    }

    private func compute(trades: [Trade], candles: [Candlestick]) -> BKComputedBacktestMetrics? {
        guard !trades.isEmpty else { return nil }

        var tradeReturns: [Double] = []
        tradeReturns.reserveCapacity(trades.count)
        var holdingPeriodsInDays: [Double] = []
        holdingPeriodsInDays.reserveCapacity(trades.count)
        var totalReturn = 0.0
        var cumulativeReturn = 0.0
        var additiveEquityCurve: [Double] = []
        additiveEquityCurve.reserveCapacity(trades.count)
        var compoundedEquityCurve: [Double] = []
        compoundedEquityCurve.reserveCapacity(trades.count)
        var compoundedEquity = 1.0

        for trade in trades {
            guard let tradeReturn = trade.bkReturn else { continue }
            tradeReturns.append(tradeReturn)
            totalReturn += tradeReturn
            cumulativeReturn += tradeReturn
            additiveEquityCurve.append(cumulativeReturn)
            compoundedEquity *= (1 + tradeReturn)
            compoundedEquityCurve.append(compoundedEquity)

            if let holdingDays = trade.bkHoldingPeriodDays() {
                holdingPeriodsInDays.append(holdingDays)
            }
        }

        let numTrades = tradeReturns.count
        guard numTrades > 0 else { return nil }

        var numWins = 0
        var numLosses = 0
        var sumWins = 0.0
        var sumLosses = 0.0
        for tradeReturn in tradeReturns {
            if tradeReturn > 0 {
                numWins += 1
                sumWins += tradeReturn
            } else if tradeReturn < 0 {
                numLosses += 1
                sumLosses += tradeReturn
            }
        }

        let avgTradeReturn = totalReturn / Double(numTrades)
        let avgWin = numWins > 0 ? sumWins / Double(numWins) : 0
        let avgLoss = numLosses > 0 ? sumLosses / Double(numLosses) : 0
        let winRate = Double(numWins) / Double(numTrades)
        let probLoss = Double(numLosses) / Double(numTrades)
        let expectancy = (winRate * avgWin) + (probLoss * avgLoss)

        var maxDrawdown = 0.0
        var additivePeak = 0.0
        for equity in additiveEquityCurve {
            if equity > additivePeak { additivePeak = equity }
            let drawdown = additivePeak - equity
            if drawdown > maxDrawdown { maxDrawdown = drawdown }
        }

        var maxDrawdownPercent = 0.0
        var drawdownPercentSum = 0.0
        var squaredDrawdownPercentSum = 0.0
        var compoundedPeak = 1.0
        for equity in compoundedEquityCurve {
            if equity > compoundedPeak { compoundedPeak = equity }
            let drawdownPercent = compoundedPeak > 0 ? (compoundedPeak - equity) / compoundedPeak : 0
            if drawdownPercent > maxDrawdownPercent {
                maxDrawdownPercent = drawdownPercent
            }
            drawdownPercentSum += drawdownPercent
            squaredDrawdownPercentSum += drawdownPercent * drawdownPercent
        }
        let averageDrawdownPercent = drawdownPercentSum / Double(numTrades)
        let ulcerIndex = sqrt(squaredDrawdownPercentSum / Double(numTrades))

        let meanReturn = avgTradeReturn
        let variance: Double
        if numTrades > 1 {
            let sumSquares = tradeReturns.reduce(0.0) { partial, value in
                let diff = value - meanReturn
                return partial + (diff * diff)
            }
            variance = sumSquares / Double(numTrades - 1)
        } else {
            variance = 0
        }
        let stdDevReturn = sqrt(max(variance, 0))
        let sharpeRatio = stdDevReturn > 0 ? (meanReturn / stdDevReturn) * sqrt(Double(numTrades)) : 0

        let downsideSquaredSum = tradeReturns.reduce(0.0) { partial, value in
            let downside = min(value, 0)
            return partial + (downside * downside)
        }
        let downsideDeviation = sqrt(downsideSquaredSum / Double(numTrades))
        let sortinoRatio = downsideDeviation > 0 ? (meanReturn / downsideDeviation) * sqrt(Double(numTrades)) : 0

        let volatility = stdDevReturn
        let profitFactor = sumLosses != 0 ? (sumWins / abs(sumLosses)) : 0

        var maxConsecutiveWins = 0
        var maxConsecutiveLosses = 0
        var currentConsecutiveWins = 0
        var currentConsecutiveLosses = 0
        for tradeReturn in tradeReturns {
            if tradeReturn > 0 {
                currentConsecutiveWins += 1
                currentConsecutiveLosses = 0
            } else if tradeReturn < 0 {
                currentConsecutiveLosses += 1
                currentConsecutiveWins = 0
            } else {
                currentConsecutiveWins = 0
                currentConsecutiveLosses = 0
            }
            if currentConsecutiveWins > maxConsecutiveWins {
                maxConsecutiveWins = currentConsecutiveWins
            }
            if currentConsecutiveLosses > maxConsecutiveLosses {
                maxConsecutiveLosses = currentConsecutiveLosses
            }
        }

        let avgHoldingPeriod = holdingPeriodsInDays.isEmpty
            ? 0
            : holdingPeriodsInDays.reduce(0, +) / Double(holdingPeriodsInDays.count)

        let dateRangeDays: Int = {
            guard let firstDate = candles.first?.date, let lastDate = candles.last?.date else { return 0 }
            return Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0
        }()
        let years = dateRangeDays > 0 ? Double(dateRangeDays) / 365.0 : 1.0
        let annualizedReturn = (1 + totalReturn) > 0 ? pow(1 + totalReturn, 1.0 / years) - 1 : 0
        let cagr = compoundedEquity > 0 ? pow(compoundedEquity, 1.0 / years) - 1 : 0
        let calmarRatio = maxDrawdownPercent > 0 ? cagr / maxDrawdownPercent : 0

        let payoffRatio = (avgWin > 0 && avgLoss < 0) ? (avgWin / abs(avgLoss)) : 0
        let kellyCriterion = payoffRatio > 0 ? (winRate - (probLoss / payoffRatio)) : 0
        let totalCompoundedReturn = compoundedEquity - 1
        let recoveryFactor = maxDrawdownPercent > 0 ? totalCompoundedReturn / maxDrawdownPercent : 0

        return BKComputedBacktestMetrics(
            trades: trades,
            tradeReturns: tradeReturns,
            additiveEquityCurve: additiveEquityCurve,
            compoundedEquityCurve: compoundedEquityCurve,
            totalReturn: totalReturn,
            annualizedReturn: annualizedReturn,
            winRate: winRate,
            maxDrawdown: maxDrawdown,
            maxDrawdownPercent: maxDrawdownPercent,
            averageDrawdownPercent: averageDrawdownPercent,
            sharpeRatio: sharpeRatio,
            avgTradeReturn: avgTradeReturn,
            numTrades: numTrades,
            numWins: numWins,
            numLosses: numLosses,
            profitFactor: profitFactor,
            expectancy: expectancy,
            cagr: cagr,
            volatility: volatility,
            downsideDeviation: downsideDeviation,
            sortinoRatio: sortinoRatio,
            calmarRatio: calmarRatio,
            avgHoldingPeriod: avgHoldingPeriod,
            maxConsecutiveWins: maxConsecutiveWins,
            maxConsecutiveLosses: maxConsecutiveLosses,
            avgWin: avgWin,
            avgLoss: avgLoss,
            kellyCriterion: kellyCriterion,
            ulcerIndex: ulcerIndex,
            totalCompoundedReturn: totalCompoundedReturn,
            payoffRatio: payoffRatio,
            recoveryFactor: recoveryFactor
        )
    }
}
