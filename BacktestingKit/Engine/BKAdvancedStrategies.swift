import Foundation

public extension BacktestingKitManager {
    func backtestEMACrossover(candles: [Candlestick], fast: Int, slow: Int) -> BacktestResult {
        guard fast < slow, candles.count >= slow else {
            return bkEmptyBacktestResult()
        }

        let uuid = "ema_crossover"
        let fastKey = "ema_\(fast)_\(uuid)"
        let slowKey = "ema_\(slow)_\(uuid)"
        let withFast = exponentialMovingAverage(candles, period: fast, uuid: uuid)
        let withBoth = exponentialMovingAverage(withFast, period: slow, uuid: uuid)

        return backtest(
            candles: withBoth,
            uuid: uuid,
            indicators: [],
            entrySignal: { prev, curr in
                guard
                    let fastPrev = prev.candles[prev.index].technicalIndicators[fastKey],
                    let slowPrev = prev.candles[prev.index].technicalIndicators[slowKey],
                    let fastCurr = curr.candles[curr.index].technicalIndicators[fastKey],
                    let slowCurr = curr.candles[curr.index].technicalIndicators[slowKey]
                else { return false }
                return fastPrev < slowPrev && fastCurr >= slowCurr
            },
            exitSignal: { prev, curr, _ in
                guard
                    let fastPrev = prev.candles[prev.index].technicalIndicators[fastKey],
                    let slowPrev = prev.candles[prev.index].technicalIndicators[slowKey],
                    let fastCurr = curr.candles[curr.index].technicalIndicators[fastKey],
                    let slowCurr = curr.candles[curr.index].technicalIndicators[slowKey]
                else { return false }
                return fastPrev > slowPrev && fastCurr <= slowCurr
            }
        )
    }

    func backtestRSIMeanReversionWithTrendFilter(
        candles: [Candlestick],
        rsiPeriod: Int = 14,
        oversold: Double = 30,
        overbought: Double = 70,
        trendPeriod: Int = 200
    ) -> BacktestResult {
        guard candles.count > max(rsiPeriod + 2, trendPeriod) else {
            return bkEmptyBacktestResult()
        }
        let uuid = "rsi_mr_trend"
        let rsiKey = "rsi_\(rsiPeriod)_\(uuid)"
        let trendKey = "sma_\(trendPeriod)_\(uuid)"
        let withRSI = relativeStrengthIndex(candles, period: rsiPeriod, uuid: uuid)
        let enriched = simpleMovingAverage(withRSI, period: trendPeriod, name: trendKey)

        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let bar = curr.candles[curr.index]
                guard
                    let rsi = bar.technicalIndicators[rsiKey],
                    let trend = bar.technicalIndicators[trendKey]
                else { return false }
                return bar.close > trend && rsi <= oversold
            },
            exitSignal: { _, curr, _ in
                guard let rsi = curr.candles[curr.index].technicalIndicators[rsiKey] else { return false }
                return rsi >= overbought
            }
        )
    }

    func backtestBreakoutWithATRStop(
        candles: [Candlestick],
        breakoutPeriod: Int = 20,
        atrPeriod: Int = 14,
        atrStopMultiplier: Double = 2.0
    ) -> BacktestResult {
        guard candles.count > max(breakoutPeriod, atrPeriod) else {
            return bkEmptyBacktestResult()
        }
        let uuid = "breakout_atr"
        let atrKey = "atr_\(atrPeriod)_\(uuid)"
        let enriched = averageTrueRange(candles, period: atrPeriod, uuid: uuid)

        var tradeLifecycle = BKTradeLifecycle()
        var inPosition = false
        var stopPrice = 0.0

        for i in breakoutPeriod..<enriched.count {
            let recentHigh = enriched[(i - breakoutPeriod)..<i].map(\.high).max() ?? enriched[i].high
            let bar = enriched[i]

            if !inPosition {
                if bar.close > recentHigh, let atr = bar.technicalIndicators[atrKey] {
                    inPosition = true
                    let entryPrice = bar.close
                    let entryDate = bar.date
                    stopPrice = bar.close - (atr * atrStopMultiplier)
                    tradeLifecycle.openLong(entryDate: entryDate, entryPrice: entryPrice)
                }
            } else {
                if bar.close <= stopPrice {
                    inPosition = false
                    tradeLifecycle.closeLatestOpen(exitDate: bar.date, exitPrice: bar.close)
                } else if let atr = bar.technicalIndicators[atrKey] {
                    stopPrice = max(stopPrice, bar.close - (atr * atrStopMultiplier))
                }
            }
        }

        if inPosition, let last = enriched.last {
            tradeLifecycle.closeLatestOpen(exitDate: last.date, exitPrice: last.close)
        }
        return buildMetricsReport(trades: tradeLifecycle.trades, candles: candles).result
    }

    func backtestRegimeSwitching(
        candles: [Candlestick],
        adxPeriod: Int = 14,
        adxThreshold: Double = 25,
        trendFast: Int = 20,
        trendSlow: Int = 50,
        rsiPeriod: Int = 14,
        rsiLow: Double = 30,
        rsiHigh: Double = 70
    ) -> BacktestResult {
        guard candles.count > max(trendSlow, adxPeriod + 1) else {
            return bkEmptyBacktestResult()
        }

        let uuid = "regime_switch"
        let adxKey = "adx_\(adxPeriod)_\(uuid)"
        let fastKey = "ema_\(trendFast)_\(uuid)"
        let slowKey = "ema_\(trendSlow)_\(uuid)"
        let rsiKey = "rsi_\(rsiPeriod)_\(uuid)"

        let withAdx = adx(candles, period: adxPeriod, uuid: uuid)
        let withFast = exponentialMovingAverage(withAdx, period: trendFast, uuid: uuid)
        let withSlow = exponentialMovingAverage(withFast, period: trendSlow, uuid: uuid)
        let enriched = relativeStrengthIndex(withSlow, period: rsiPeriod, uuid: uuid)

        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let bar = curr.candles[curr.index]
                guard
                    let adxVal = bar.technicalIndicators[adxKey],
                    let fast = bar.technicalIndicators[fastKey],
                    let slow = bar.technicalIndicators[slowKey],
                    let rsi = bar.technicalIndicators[rsiKey]
                else { return false }
                if adxVal >= adxThreshold {
                    return fast > slow
                }
                return rsi <= rsiLow
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard
                    let adxVal = bar.technicalIndicators[adxKey],
                    let fast = bar.technicalIndicators[fastKey],
                    let slow = bar.technicalIndicators[slowKey],
                    let rsi = bar.technicalIndicators[rsiKey]
                else { return false }
                if adxVal >= adxThreshold {
                    return fast < slow
                }
                return rsi >= rsiHigh
            }
        )
    }

    func executionAdjustedTrades(
        trades: [Trade],
        quantity: Double = 1.0,
        slippageModel: BKSlippageModel = BKNoSlippageModel(),
        commissionModel: BKCommissionModel = BKNoCommissionModel()
    ) -> [BKExecutionAdjustedTrade] {
        guard quantity > 0 else { return [] }
        return trades.compactMap { trade in
            guard let exitPrice = trade.exitPrice, let exitDate = trade.exitDate else { return nil }
            let entry = slippageModel.slippagePrice(referencePrice: trade.entryPrice, quantity: quantity, isBuy: true)
            let exit = slippageModel.slippagePrice(referencePrice: exitPrice, quantity: quantity, isBuy: false)
            let entryNotional = entry * quantity
            let exitNotional = exit * quantity
            let commissions = commissionModel.commission(notional: entryNotional, quantity: quantity)
                + commissionModel.commission(notional: exitNotional, quantity: quantity)
            let gross = (exit - entry) * quantity
            let net = gross - commissions
            return BKExecutionAdjustedTrade(
                entryDate: trade.entryDate,
                exitDate: exitDate,
                entryPrice: entry,
                exitPrice: exit,
                quantity: quantity,
                grossPnl: gross,
                netPnl: net,
                commissions: commissions
            )
        }
    }
}
