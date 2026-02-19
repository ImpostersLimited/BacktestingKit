import Foundation

public extension BacktestingKitManager {
    /// Donchian breakout strategy with ATR-based trailing stop management.
    ///
    /// - Parameters:
    ///   - candles: Input OHLCV candles in chronological order.
    ///   - breakoutPeriod: Lookback window used to detect breakout highs.
    ///   - atrPeriod: ATR period used for stop distance estimation.
    ///   - atrStopMultiplier: Multiplier applied to ATR for trailing stop width.
    /// - Returns: Backtest result for the strategy run.
    func backtestDonchianBreakoutWithATRStop(
        candles: [Candlestick],
        breakoutPeriod: Int = 20,
        atrPeriod: Int = 14,
        atrStopMultiplier: Double = 2.0
    ) -> BacktestResult {
        guard candles.count > max(breakoutPeriod, atrPeriod) else {
            return bkEmptyBacktestResult()
        }

        let uuid = "donchian_atr"
        let atrKey = "atr_\(atrPeriod)_\(uuid)"
        let enriched = averageTrueRange(candles, period: atrPeriod, uuid: uuid)

        var tradeLifecycle = BKTradeLifecycle()
        var inPosition = false
        var trailingStop = 0.0

        for i in breakoutPeriod..<enriched.count {
            let bar = enriched[i]
            let breakoutHigh = enriched[(i - breakoutPeriod)..<i].map(\.high).max() ?? bar.high

            if !inPosition {
                if bar.close > breakoutHigh, let atr = bar.technicalIndicators[atrKey] {
                    inPosition = true
                    let entryPrice = bar.close
                    let entryDate = bar.date
                    trailingStop = bar.close - (atr * atrStopMultiplier)
                    tradeLifecycle.openLong(entryDate: entryDate, entryPrice: entryPrice)
                }
                continue
            }

            if bar.close <= trailingStop {
                inPosition = false
                tradeLifecycle.closeLatestOpen(exitDate: bar.date, exitPrice: bar.close)
            } else if let atr = bar.technicalIndicators[atrKey] {
                trailingStop = max(trailingStop, bar.close - (atr * atrStopMultiplier))
            }
        }

        if inPosition, let last = enriched.last {
            tradeLifecycle.closeLatestOpen(exitDate: last.date, exitPrice: last.close)
        }

        return buildMetricsReport(trades: tradeLifecycle.trades, candles: candles).result
    }

    /// Supertrend-based trend-following strategy.
    ///
    /// - Parameters:
    ///   - candles: Input OHLCV candles in chronological order.
    ///   - atrPeriod: ATR period used in Supertrend band construction.
    ///   - multiplier: ATR multiplier for upper/lower Supertrend bands.
    /// - Returns: Backtest result for the strategy run.
    func backtestSupertrend(
        candles: [Candlestick],
        atrPeriod: Int = 10,
        multiplier: Double = 3.0
    ) -> BacktestResult {
        guard candles.count > atrPeriod else {
            return bkEmptyBacktestResult()
        }

        let uuid = "supertrend"
        let atrKey = "atr_\(atrPeriod)_\(uuid)"
        let withAtr = averageTrueRange(candles, period: atrPeriod, uuid: uuid)
        let trendKey = "supertrend_\(atrPeriod)_\(uuid)"

        var result = withAtr
        var finalUpper: Double = 0
        var finalLower: Double = 0
        var supertrend: Double = 0
        var bullish = true

        for i in 0..<result.count {
            let bar = result[i]
            guard let atr = bar.technicalIndicators[atrKey] else { continue }
            let hl2 = (bar.high + bar.low) / 2
            let basicUpper = hl2 + (multiplier * atr)
            let basicLower = hl2 - (multiplier * atr)

            if i == 0 {
                finalUpper = basicUpper
                finalLower = basicLower
                supertrend = basicLower
                bullish = true
            } else {
                let prevClose = result[i - 1].close
                finalUpper = (basicUpper < finalUpper || prevClose > finalUpper) ? basicUpper : finalUpper
                finalLower = (basicLower > finalLower || prevClose < finalLower) ? basicLower : finalLower

                if supertrend == finalUpper {
                    bullish = bar.close > finalUpper
                } else {
                    bullish = bar.close >= finalLower
                }
                supertrend = bullish ? finalLower : finalUpper
            }

            var ti = result[i].technicalIndicators
            ti[trendKey] = supertrend
            result[i] = result[i].replacingTechnicalIndicators(ti)
        }

        return backtest(
            candles: result,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let bar = curr.candles[curr.index]
                guard let st = bar.technicalIndicators[trendKey] else { return false }
                return bar.close > st
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard let st = bar.technicalIndicators[trendKey] else { return false }
                return bar.close < st
            }
        )
    }

    /// Dual EMA crossover strategy filtered by ADX regime strength.
    ///
    /// - Parameters:
    ///   - candles: Input OHLCV candles in chronological order.
    ///   - fastPeriod: Fast EMA period.
    ///   - slowPeriod: Slow EMA period.
    ///   - adxPeriod: ADX period.
    ///   - adxThreshold: Minimum ADX required to allow entries.
    /// - Returns: Backtest result for the strategy run.
    func backtestDualEMAWithADXFilter(
        candles: [Candlestick],
        fastPeriod: Int = 20,
        slowPeriod: Int = 50,
        adxPeriod: Int = 14,
        adxThreshold: Double = 20
    ) -> BacktestResult {
        guard candles.count > max(slowPeriod, adxPeriod + 1) else {
            return bkEmptyBacktestResult()
        }

        let uuid = "dual_ema_adx"
        let fastKey = "ema_\(fastPeriod)_\(uuid)"
        let slowKey = "ema_\(slowPeriod)_\(uuid)"
        let adxKey = "adx_\(adxPeriod)_\(uuid)"

        let withAdx = adx(candles, period: adxPeriod, uuid: uuid)
        let withFast = exponentialMovingAverage(withAdx, period: fastPeriod, uuid: uuid)
        let enriched = exponentialMovingAverage(withFast, period: slowPeriod, uuid: uuid)

        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let bar = curr.candles[curr.index]
                guard
                    let fast = bar.technicalIndicators[fastKey],
                    let slow = bar.technicalIndicators[slowKey],
                    let adxValue = bar.technicalIndicators[adxKey]
                else { return false }
                return fast > slow && adxValue >= adxThreshold
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard
                    let fast = bar.technicalIndicators[fastKey],
                    let slow = bar.technicalIndicators[slowKey]
                else { return false }
                return fast < slow
            }
        )
    }

    /// Bollinger z-score mean reversion strategy.
    ///
    /// - Parameters:
    ///   - candles: Input OHLCV candles in chronological order.
    ///   - period: Bollinger period.
    ///   - numStdDev: Standard deviation multiplier for bands.
    ///   - entryZ: Entry threshold on z-score (typically negative).
    ///   - exitZ: Exit threshold on z-score.
    /// - Returns: Backtest result for the strategy run.
    func backtestBollingerZScoreMeanReversion(
        candles: [Candlestick],
        period: Int = 20,
        numStdDev: Double = 2.0,
        entryZ: Double = -1.0,
        exitZ: Double = 0.0
    ) -> BacktestResult {
        guard candles.count >= period else {
            return bkEmptyBacktestResult()
        }

        let uuid = "bb_zscore_mr"
        let middleKey = "bbMiddle_\(period)_\(uuid)"
        let upperKey = "bbUpper_\(period)_\(numStdDev)_\(uuid)"
        let zKey = "zscore_\(period)_\(uuid)"

        let withBands = bollingerBands(candles, period: period, numStdDev: numStdDev, uuid: uuid)
        var enriched = withBands

        for i in 0..<enriched.count {
            guard
                let middle = enriched[i].technicalIndicators[middleKey],
                let upper = enriched[i].technicalIndicators[upperKey]
            else { continue }
            let std = max((upper - middle) / max(numStdDev, 0.000001), 0.000001)
            let z = (enriched[i].close - middle) / std
            var ti = enriched[i].technicalIndicators
            ti[zKey] = z
            enriched[i] = enriched[i].replacingTechnicalIndicators(ti)
        }

        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                guard let z = curr.candles[curr.index].technicalIndicators[zKey] else { return false }
                return z <= entryZ
            },
            exitSignal: { _, curr, _ in
                guard let z = curr.candles[curr.index].technicalIndicators[zKey] else { return false }
                return z >= exitZ
            }
        )
    }

    /// RSI(2) short-horizon mean reversion strategy with long-term trend filter.
    ///
    /// - Parameters:
    ///   - candles: Input OHLCV candles in chronological order.
    ///   - trendPeriod: Trend SMA period used as a bullish regime filter.
    ///   - entryThreshold: RSI(2) entry threshold.
    ///   - exitThreshold: RSI(2) exit threshold.
    /// - Returns: Backtest result for the strategy run.
    func backtestRSI2MeanReversion(
        candles: [Candlestick],
        trendPeriod: Int = 200,
        entryThreshold: Double = 10,
        exitThreshold: Double = 60
    ) -> BacktestResult {
        backtestRSIMeanReversionWithTrendFilter(
            candles: candles,
            rsiPeriod: 2,
            oversold: entryThreshold,
            overbought: exitThreshold,
            trendPeriod: trendPeriod
        )
    }

    /// EMA fast/slow trend strategy with ATR-based trailing stop.
    ///
    /// - Parameters:
    ///   - candles: Input OHLCV candles in chronological order.
    ///   - fastPeriod: Fast EMA period.
    ///   - slowPeriod: Slow EMA period.
    ///   - atrPeriod: ATR period for stop sizing.
    ///   - atrStopMultiplier: ATR multiplier for trailing stop width.
    /// - Returns: Backtest result for the strategy run.
    func backtestEMAFastSlowWithATRStop(
        candles: [Candlestick],
        fastPeriod: Int = 12,
        slowPeriod: Int = 26,
        atrPeriod: Int = 14,
        atrStopMultiplier: Double = 2.0
    ) -> BacktestResult {
        guard candles.count > max(slowPeriod, atrPeriod) else { return bkEmptyBacktestResult() }
        let uuid = "ema_fast_slow_atr"
        let fastKey = "ema_\(fastPeriod)_\(uuid)"
        let slowKey = "ema_\(slowPeriod)_\(uuid)"
        let atrKey = "atr_\(atrPeriod)_\(uuid)"
        let withAtr = averageTrueRange(candles, period: atrPeriod, uuid: uuid)
        let withFast = exponentialMovingAverage(withAtr, period: fastPeriod, uuid: uuid)
        let enriched = exponentialMovingAverage(withFast, period: slowPeriod, uuid: uuid)

        var tradeLifecycle = BKTradeLifecycle()
        var inPosition = false
        var trailingStop = 0.0

        for i in 1..<enriched.count {
            let bar = enriched[i]
            guard
                let fast = bar.technicalIndicators[fastKey],
                let slow = bar.technicalIndicators[slowKey]
            else { continue }
            let prev = enriched[i - 1]
            let prevFast = prev.technicalIndicators[fastKey]
            let prevSlow = prev.technicalIndicators[slowKey]

            if !inPosition {
                if let pf = prevFast, let ps = prevSlow, pf <= ps, fast > slow, let atr = bar.technicalIndicators[atrKey] {
                    inPosition = true
                    trailingStop = bar.close - (atr * atrStopMultiplier)
                    tradeLifecycle.openLong(entryDate: bar.date, entryPrice: bar.close)
                }
                continue
            }

            if bar.close <= trailingStop || fast < slow {
                inPosition = false
                tradeLifecycle.closeLatestOpen(exitDate: bar.date, exitPrice: bar.close)
            } else if let atr = bar.technicalIndicators[atrKey] {
                trailingStop = max(trailingStop, bar.close - (atr * atrStopMultiplier))
            }
        }

        if inPosition, let last = enriched.last {
            tradeLifecycle.closeLatestOpen(exitDate: last.date, exitPrice: last.close)
        }
        return buildMetricsReport(trades: tradeLifecycle.trades, candles: candles).result
    }

    /// Backward-compatible alias.
    func backtestEMA1226WithATRStop(
        candles: [Candlestick],
        atrPeriod: Int = 14,
        atrStopMultiplier: Double = 2.0
    ) -> BacktestResult {
        backtestEMAFastSlowWithATRStop(
            candles: candles,
            fastPeriod: 12,
            slowPeriod: 26,
            atrPeriod: atrPeriod,
            atrStopMultiplier: atrStopMultiplier
        )
    }

    /// Turtle-style Donchian breakout with configurable entry/exit windows and ATR stop.
    func backtestDonchianBreakoutWithATRStop(
        candles: [Candlestick],
        entryPeriod: Int = 55,
        exitPeriod: Int = 20,
        atrPeriod: Int = 14,
        atrStopMultiplier: Double = 2.0
    ) -> BacktestResult {
        guard candles.count > max(entryPeriod, exitPeriod, atrPeriod) else { return bkEmptyBacktestResult() }
        let uuid = "donchian2055_atr"
        let atrKey = "atr_\(atrPeriod)_\(uuid)"
        let enriched = averageTrueRange(candles, period: atrPeriod, uuid: uuid)

        var tradeLifecycle = BKTradeLifecycle()
        var inPosition = false
        var trailingStop = 0.0

        for i in entryPeriod..<enriched.count {
            let bar = enriched[i]
            let entryHigh = enriched[(i - entryPeriod)..<i].map(\.high).max() ?? bar.high
            let exitLow = i >= exitPeriod ? (enriched[(i - exitPeriod)..<i].map(\.low).min() ?? bar.low) : bar.low

            if !inPosition {
                if bar.close > entryHigh, let atr = bar.technicalIndicators[atrKey] {
                    inPosition = true
                    trailingStop = bar.close - (atr * atrStopMultiplier)
                    tradeLifecycle.openLong(entryDate: bar.date, entryPrice: bar.close)
                }
                continue
            }

            if bar.close < exitLow || bar.close <= trailingStop {
                inPosition = false
                tradeLifecycle.closeLatestOpen(exitDate: bar.date, exitPrice: bar.close)
            } else if let atr = bar.technicalIndicators[atrKey] {
                trailingStop = max(trailingStop, bar.close - (atr * atrStopMultiplier))
            }
        }

        if inPosition, let last = enriched.last {
            tradeLifecycle.closeLatestOpen(exitDate: last.date, exitPrice: last.close)
        }
        return buildMetricsReport(trades: tradeLifecycle.trades, candles: candles).result
    }

    /// Backward-compatible alias.
    func backtestDonchian2055WithATRPositionSizing(
        candles: [Candlestick],
        entryPeriod: Int = 55,
        exitPeriod: Int = 20,
        atrPeriod: Int = 14,
        atrStopMultiplier: Double = 2.0
    ) -> BacktestResult {
        backtestDonchianBreakoutWithATRStop(
            candles: candles,
            entryPeriod: entryPeriod,
            exitPeriod: exitPeriod,
            atrPeriod: atrPeriod,
            atrStopMultiplier: atrStopMultiplier
        )
    }

    /// SMA crossover filtered by ADX regime strength.
    func backtestSMACrossoverWithRegimeFilter(
        candles: [Candlestick],
        fastPeriod: Int = 50,
        slowPeriod: Int = 200,
        adxPeriod: Int = 14,
        adxThreshold: Double = 20
    ) -> BacktestResult {
        guard candles.count > max(slowPeriod, adxPeriod + 1) else { return bkEmptyBacktestResult() }
        let uuid = "sma_regime_adx"
        let fastKey = "sma_\(fastPeriod)_\(uuid)"
        let slowKey = "sma_\(slowPeriod)_\(uuid)"
        let adxKey = "adx_\(adxPeriod)_\(uuid)"
        let withAdx = adx(candles, period: adxPeriod, uuid: uuid)
        let withFast = simpleMovingAverage(withAdx, period: fastPeriod, name: fastKey)
        let enriched = simpleMovingAverage(withFast, period: slowPeriod, name: slowKey)

        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let bar = curr.candles[curr.index]
                guard
                    let fast = bar.technicalIndicators[fastKey],
                    let slow = bar.technicalIndicators[slowKey],
                    let adxValue = bar.technicalIndicators[adxKey]
                else { return false }
                return fast > slow && adxValue >= adxThreshold
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard let fast = bar.technicalIndicators[fastKey], let slow = bar.technicalIndicators[slowKey] else { return false }
                return fast < slow
            }
        )
    }

    /// Bollinger-band mean reversion using lower-band entries and middle-band exits.
    func backtestBollingerBandReversion(
        candles: [Candlestick],
        period: Int = 20,
        numStdDev: Double = 2.0
    ) -> BacktestResult {
        guard candles.count >= period else { return bkEmptyBacktestResult() }
        let uuid = "bb_reversion"
        let lowerKey = "bbLower_\(period)_\(numStdDev)_\(uuid)"
        let middleKey = "bbMiddle_\(period)_\(uuid)"
        let enriched = bollingerBands(candles, period: period, numStdDev: numStdDev, uuid: uuid)
        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let bar = curr.candles[curr.index]
                guard let lower = bar.technicalIndicators[lowerKey] else { return false }
                return bar.close <= lower
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard let middle = bar.technicalIndicators[middleKey] else { return false }
                return bar.close >= middle
            }
        )
    }

    /// Generic close-price z-score mean reversion.
    func backtestZScoreReversion(
        candles: [Candlestick],
        lookback: Int = 20,
        entryZ: Double = -2.0,
        exitZ: Double = 0.0
    ) -> BacktestResult {
        guard candles.count > lookback else { return bkEmptyBacktestResult() }
        let uuid = "zscore_reversion_\(lookback)"
        let zKey = "zscore_\(lookback)_\(uuid)"
        var enriched = candles
        var closes: [Double] = []
        closes.reserveCapacity(candles.count)

        for i in 0..<candles.count {
            closes.append(candles[i].close)
            if closes.count < lookback { continue }
            let window = closes[(closes.count - lookback)...]
            let mean = window.reduce(0, +) / Double(lookback)
            let variance = window.reduce(0) { partial, value in
                partial + (value - mean) * (value - mean)
            } / Double(lookback)
            let std = max(sqrt(variance), 0.000001)
            var ti = enriched[i].technicalIndicators
            ti[zKey] = (candles[i].close - mean) / std
            enriched[i] = enriched[i].replacingTechnicalIndicators(ti)
        }

        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                guard let z = curr.candles[curr.index].technicalIndicators[zKey] else { return false }
                return z <= entryZ
            },
            exitSignal: { _, curr, _ in
                guard let z = curr.candles[curr.index].technicalIndicators[zKey] else { return false }
                return z >= exitZ
            }
        )
    }

    /// VWAP spread z-score mean reversion strategy.
    ///
    /// - Parameters:
    ///   - candles: Input OHLCV candles in chronological order.
    ///   - rollingStdPeriod: Window used for spread normalization.
    ///   - entryZ: Entry threshold on VWAP spread z-score.
    ///   - exitZ: Exit threshold on VWAP spread z-score.
    /// - Returns: Backtest result for the strategy run.
    func backtestVWAPReversion(
        candles: [Candlestick],
        rollingStdPeriod: Int = 20,
        entryZ: Double = -1.5,
        exitZ: Double = 0.0
    ) -> BacktestResult {
        guard candles.count > rollingStdPeriod else {
            return bkEmptyBacktestResult()
        }

        let uuid = "vwap_reversion"
        let vwapKey = "vwap_\(uuid)"
        let zKey = "vwap_z_\(uuid)"
        let withVWAP = vwap(candles, uuid: uuid)
        var enriched = withVWAP
        var spreads: [Double] = Array(repeating: 0, count: withVWAP.count)

        for i in 0..<withVWAP.count {
            let v = withVWAP[i].technicalIndicators[vwapKey] ?? withVWAP[i].close
            spreads[i] = withVWAP[i].close - v
            if i + 1 < rollingStdPeriod {
                continue
            }
            let window = spreads[(i - rollingStdPeriod + 1)...i]
            let mean = window.reduce(0, +) / Double(rollingStdPeriod)
            let variance = window.reduce(0) { partial, value in
                partial + (value - mean) * (value - mean)
            } / Double(rollingStdPeriod)
            let std = max(sqrt(variance), 0.000001)
            let z = (spreads[i] - mean) / std
            var ti = enriched[i].technicalIndicators
            ti[zKey] = z
            enriched[i] = enriched[i].replacingTechnicalIndicators(ti)
        }

        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                guard let z = curr.candles[curr.index].technicalIndicators[zKey] else { return false }
                return z <= entryZ
            },
            exitSignal: { _, curr, _ in
                guard let z = curr.candles[curr.index].technicalIndicators[zKey] else { return false }
                return z >= exitZ
            }
        )
    }

    /// Breakout strategy requiring OBV confirmation.
    ///
    /// - Parameters:
    ///   - candles: Input OHLCV candles in chronological order.
    ///   - breakoutPeriod: Lookback window for price breakout checks.
    ///   - obvSmaPeriod: Smoothing period for OBV trend confirmation.
    /// - Returns: Backtest result for the strategy run.
    func backtestOBVTrendConfirmationBreakout(
        candles: [Candlestick],
        breakoutPeriod: Int = 20,
        obvSmaPeriod: Int = 20
    ) -> BacktestResult {
        guard candles.count > max(breakoutPeriod, obvSmaPeriod) else {
            return bkEmptyBacktestResult()
        }

        let uuid = "obv_breakout"
        let obvKey = "obv_\(uuid)"
        let obvSmaKey = "obv_sma_\(obvSmaPeriod)_\(uuid)"
        let withOBV = onBalanceVolume(candles, uuid: uuid)
        var enriched = withOBV

        for i in (obvSmaPeriod - 1)..<withOBV.count {
            let window = withOBV[(i - obvSmaPeriod + 1)...i]
            let obvValues = window.compactMap { $0.technicalIndicators[obvKey] }
            guard obvValues.count == obvSmaPeriod else { continue }
            let avg = obvValues.reduce(0, +) / Double(obvSmaPeriod)
            var ti = enriched[i].technicalIndicators
            ti[obvSmaKey] = avg
            enriched[i] = enriched[i].replacingTechnicalIndicators(ti)
        }

        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let i = curr.index
                guard i >= breakoutPeriod else { return false }
                let recentHigh = curr.candles[(i - breakoutPeriod)..<i].map(\.high).max() ?? curr.candles[i].high
                let bar = curr.candles[i]
                guard
                    let obv = bar.technicalIndicators[obvKey],
                    let obvSma = bar.technicalIndicators[obvSmaKey]
                else { return false }
                return bar.close > recentHigh && obv > obvSma
            },
            exitSignal: { _, curr, _ in
                let i = curr.index
                guard i >= breakoutPeriod else { return false }
                let recentLow = curr.candles[(i - breakoutPeriod)..<i].map(\.low).min() ?? curr.candles[i].low
                return curr.candles[i].close < recentLow
            }
        )
    }

    /// MFI oversold mean reversion strategy constrained by trend filter.
    ///
    /// - Parameters:
    ///   - candles: Input OHLCV candles in chronological order.
    ///   - mfiPeriod: MFI period.
    ///   - trendPeriod: Trend SMA period.
    ///   - oversold: Entry threshold for MFI oversold condition.
    ///   - exitThreshold: Exit threshold for MFI recovery condition.
    /// - Returns: Backtest result for the strategy run.
    func backtestMFITrendFilterReversion(
        candles: [Candlestick],
        mfiPeriod: Int = 14,
        trendPeriod: Int = 200,
        oversold: Double = 20,
        exitThreshold: Double = 60
    ) -> BacktestResult {
        guard candles.count > max(mfiPeriod, trendPeriod) else {
            return bkEmptyBacktestResult()
        }

        let uuid = "mfi_trend_mr"
        let mfiKey = "mfi_\(mfiPeriod)_\(uuid)"
        let trendKey = "sma_\(trendPeriod)_\(uuid)"

        let withMfi = moneyFlowIndex(candles, period: mfiPeriod, uuid: uuid)
        let enriched = simpleMovingAverage(withMfi, period: trendPeriod, name: trendKey)

        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let bar = curr.candles[curr.index]
                guard
                    let mfi = bar.technicalIndicators[mfiKey],
                    let trend = bar.technicalIndicators[trendKey]
                else { return false }
                return bar.close > trend && mfi <= oversold
            },
            exitSignal: { _, curr, _ in
                guard let mfi = curr.candles[curr.index].technicalIndicators[mfiKey] else { return false }
                return mfi >= exitThreshold
            }
        )
    }

    /// Volatility contraction breakout strategy using ATR squeeze detection.
    ///
    /// - Parameters:
    ///   - candles: Input OHLCV candles in chronological order.
    ///   - atrPeriod: ATR period.
    ///   - atrSmaPeriod: ATR smoothing period for contraction baseline.
    ///   - contractionThreshold: Max ATR/ATR-SMA ratio considered contracted.
    ///   - breakoutPeriod: Price breakout lookback window.
    ///   - exitSmaPeriod: Exit SMA period.
    /// - Returns: Backtest result for the strategy run.
    func backtestVolatilityContractionBreakout(
        candles: [Candlestick],
        atrPeriod: Int = 14,
        atrSmaPeriod: Int = 50,
        contractionThreshold: Double = 0.8,
        breakoutPeriod: Int = 20,
        exitSmaPeriod: Int = 20
    ) -> BacktestResult {
        guard candles.count > max(atrSmaPeriod, breakoutPeriod, exitSmaPeriod, atrPeriod) else {
            return bkEmptyBacktestResult()
        }

        let uuid = "vol_contraction_breakout"
        let atrKey = "atr_\(atrPeriod)_\(uuid)"
        let atrSmaKey = "atr_sma_\(atrSmaPeriod)_\(uuid)"
        let exitSmaKey = "sma_\(exitSmaPeriod)_\(uuid)"

        let withAtr = averageTrueRange(candles, period: atrPeriod, uuid: uuid)
        let withExitSMA = simpleMovingAverage(withAtr, period: exitSmaPeriod, name: exitSmaKey)
        var enriched = withExitSMA

        for i in (atrSmaPeriod - 1)..<withExitSMA.count {
            let window = withExitSMA[(i - atrSmaPeriod + 1)...i]
            let atrValues = window.compactMap { $0.technicalIndicators[atrKey] }
            guard atrValues.count == atrSmaPeriod else { continue }
            let avg = atrValues.reduce(0, +) / Double(atrSmaPeriod)
            var ti = enriched[i].technicalIndicators
            ti[atrSmaKey] = avg
            enriched[i] = enriched[i].replacingTechnicalIndicators(ti)
        }

        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let i = curr.index
                guard i >= breakoutPeriod else { return false }
                let bar = curr.candles[i]
                guard
                    let atr = bar.technicalIndicators[atrKey],
                    let atrSma = bar.technicalIndicators[atrSmaKey],
                    atrSma > 0
                else { return false }
                let contraction = (atr / atrSma) <= contractionThreshold
                let recentHigh = curr.candles[(i - breakoutPeriod)..<i].map(\.high).max() ?? bar.high
                return contraction && bar.close > recentHigh
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard let exitSma = bar.technicalIndicators[exitSmaKey] else { return false }
                return bar.close < exitSma
            }
        )
    }

}
