import Foundation

public extension BacktestingKitManager {
    func backtestPulseDipRebound(
        candles: [Candlestick],
        pulsePeriod: Int = 8,
        trendPeriod: Int = 55,
        rsiPeriod: Int = 6,
        rsiEntry: Double = 35,
        rsiExit: Double = 58
    ) -> BacktestResult {
        guard candles.count > max(pulsePeriod, trendPeriod, rsiPeriod + 1) else { return bkEmptyBacktestResult() }
        let uuid = "pulse_dip_rebound"
        let pulseKey = "ema_\(pulsePeriod)_\(uuid)"
        let trendKey = "sma_\(trendPeriod)_\(uuid)"
        let rsiKey = "rsi_\(rsiPeriod)_\(uuid)"

        let withTrend = simpleMovingAverage(candles, period: trendPeriod, name: trendKey)
        let withPulse = exponentialMovingAverage(withTrend, period: pulsePeriod, uuid: uuid)
        let enriched = relativeStrengthIndex(withPulse, period: rsiPeriod, uuid: uuid)

        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let bar = curr.candles[curr.index]
                guard
                    let pulse = bar.technicalIndicators[pulseKey],
                    let trend = bar.technicalIndicators[trendKey],
                    let rsi = bar.technicalIndicators[rsiKey]
                else { return false }
                return bar.close > trend && bar.close < pulse && rsi <= rsiEntry
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard let pulse = bar.technicalIndicators[pulseKey], let rsi = bar.technicalIndicators[rsiKey] else { return false }
                return bar.close > pulse || rsi >= rsiExit
            }
        )
    }

    /// Agentic preset: ride drift phases, exit on breathing-out weakness.
    func backtestDriftBreather(
        candles: [Candlestick],
        fastPeriod: Int = 13,
        slowPeriod: Int = 34,
        atrPeriod: Int = 10
    ) -> BacktestResult {
        guard candles.count > max(fastPeriod, slowPeriod, atrPeriod) else { return bkEmptyBacktestResult() }
        let uuid = "drift_breather"
        let fastKey = "ema_\(fastPeriod)_\(uuid)"
        let slowKey = "ema_\(slowPeriod)_\(uuid)"
        let atrKey = "atr_\(atrPeriod)_\(uuid)"

        let withAtr = averageTrueRange(candles, period: atrPeriod, uuid: uuid)
        let withFast = exponentialMovingAverage(withAtr, period: fastPeriod, uuid: uuid)
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
                    let atr = bar.technicalIndicators[atrKey]
                else { return false }
                return fast > slow && (bar.high - bar.low) > (atr * 0.75)
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard
                    let fast = bar.technicalIndicators[fastKey],
                    let slow = bar.technicalIndicators[slowKey],
                    let atr = bar.technicalIndicators[atrKey]
                else { return false }
                return fast < slow || (bar.high - bar.low) < (atr * 0.35)
            }
        )
    }

    /// Agentic preset: capture volatility expansion then fade once normalized.
    func backtestVolatilitySnap(
        candles: [Candlestick],
        atrPeriod: Int = 14,
        atrBaselinePeriod: Int = 40,
        expansionMultiple: Double = 1.4
    ) -> BacktestResult {
        guard candles.count > max(atrPeriod, atrBaselinePeriod) else { return bkEmptyBacktestResult() }
        let uuid = "volatility_snap"
        let atrKey = "atr_\(atrPeriod)_\(uuid)"
        let atrBaselineKey = "atr_baseline_\(atrBaselinePeriod)_\(uuid)"
        let trendKey = "sma_55_\(uuid)"

        let withAtr = averageTrueRange(candles, period: atrPeriod, uuid: uuid)
        let withTrend = simpleMovingAverage(withAtr, period: 55, name: trendKey)
        var enriched = withTrend

        for index in (atrBaselinePeriod - 1)..<enriched.count {
            let window = enriched[(index - atrBaselinePeriod + 1)...index]
            let atrs = window.compactMap { $0.technicalIndicators[atrKey] }
            guard atrs.count == atrBaselinePeriod else { continue }
            let baseline = atrs.reduce(0, +) / Double(atrBaselinePeriod)
            var ti = enriched[index].technicalIndicators
            ti[atrBaselineKey] = baseline
            enriched[index] = enriched[index].replacingTechnicalIndicators(ti)
        }

        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let bar = curr.candles[curr.index]
                guard
                    let atr = bar.technicalIndicators[atrKey],
                    let baseline = bar.technicalIndicators[atrBaselineKey],
                    let trend = bar.technicalIndicators[trendKey]
                else { return false }
                return bar.close > trend && atr >= baseline * expansionMultiple
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard
                    let atr = bar.technicalIndicators[atrKey],
                    let baseline = bar.technicalIndicators[atrBaselineKey]
                else { return false }
                return atr <= baseline
            }
        )
    }

    /// Agentic preset: reversion from below VWAP plus lower-band compression.
    func backtestBandVWAPBridge(
        candles: [Candlestick],
        period: Int = 20,
        numStdDev: Double = 1.8
    ) -> BacktestResult {
        guard candles.count >= period else { return bkEmptyBacktestResult() }
        let uuid = "band_vwap_bridge"
        let lowerKey = "bbLower_\(period)_\(numStdDev)_\(uuid)"
        let middleKey = "bbMiddle_\(period)_\(uuid)"
        let vwapKey = "vwap_\(uuid)"

        let withBands = bollingerBands(candles, period: period, numStdDev: numStdDev, uuid: uuid)
        let enriched = vwap(withBands, uuid: uuid)

        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let bar = curr.candles[curr.index]
                guard
                    let lower = bar.technicalIndicators[lowerKey],
                    let vwapValue = bar.technicalIndicators[vwapKey]
                else { return false }
                return bar.close <= lower && bar.close < vwapValue
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard
                    let middle = bar.technicalIndicators[middleKey],
                    let vwapValue = bar.technicalIndicators[vwapKey]
                else { return false }
                return bar.close >= middle || bar.close >= vwapValue
            }
        )
    }

    /// Agentic preset: enter on channel reclaim after controlled pullback.
    func backtestEchoChannelPivot(candles: [Candlestick], channelPeriod: Int = 30, signalPeriod: Int = 9) -> BacktestResult {
        guard candles.count > max(channelPeriod, signalPeriod) else { return bkEmptyBacktestResult() }
        let uuid = "echo_channel_pivot"
        let signalKey = "ema_\(signalPeriod)_\(uuid)"
        let withSignal = exponentialMovingAverage(candles, period: signalPeriod, uuid: uuid)
        return backtest(
            candles: withSignal,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let i = curr.index
                guard i >= channelPeriod else { return false }
                let bar = curr.candles[i]
                let channelLow = curr.candles[(i - channelPeriod)..<i].map(\.low).min() ?? bar.low
                guard let signal = bar.technicalIndicators[signalKey] else { return false }
                return bar.close > signal && bar.close > channelLow * 1.01
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard let signal = bar.technicalIndicators[signalKey] else { return false }
                return bar.close < signal
            }
        )
    }

    /// Agentic preset: trade release from compression ladder.
    func backtestLadderCompressionRelease(candles: [Candlestick], atrPeriod: Int = 12, baselinePeriod: Int = 25) -> BacktestResult {
        guard candles.count > max(atrPeriod, baselinePeriod) else { return bkEmptyBacktestResult() }
        let uuid = "ladder_compression_release"
        let atrKey = "atr_\(atrPeriod)_\(uuid)"
        let baseKey = "atr_base_\(baselinePeriod)_\(uuid)"
        var enriched = averageTrueRange(candles, period: atrPeriod, uuid: uuid)
        for i in (baselinePeriod - 1)..<enriched.count {
            let window = enriched[(i - baselinePeriod + 1)...i]
            let atrValues = window.compactMap { $0.technicalIndicators[atrKey] }
            guard atrValues.count == baselinePeriod else { continue }
            var ti = enriched[i].technicalIndicators
            ti[baseKey] = atrValues.reduce(0, +) / Double(baselinePeriod)
            enriched[i] = enriched[i].replacingTechnicalIndicators(ti)
        }
        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let bar = curr.candles[curr.index]
                guard let atr = bar.technicalIndicators[atrKey], let base = bar.technicalIndicators[baseKey], base > 0 else { return false }
                return atr > base * 1.25
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard let atr = bar.technicalIndicators[atrKey], let base = bar.technicalIndicators[baseKey] else { return false }
                return atr <= base
            }
        )
    }

    /// Agentic preset: latch short impulse weakness then unload on normalized momentum.
    func backtestRSIImpulseLatch(candles: [Candlestick], rsiPeriod: Int = 5, entry: Double = 28, exit: Double = 55) -> BacktestResult {
        guard candles.count > rsiPeriod + 1 else { return bkEmptyBacktestResult() }
        let uuid = "rsi_impulse_latch"
        let rsiKey = "rsi_\(rsiPeriod)_\(uuid)"
        let enriched = relativeStrengthIndex(candles, period: rsiPeriod, uuid: uuid)
        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                guard let value = curr.candles[curr.index].technicalIndicators[rsiKey] else { return false }
                return value <= entry
            },
            exitSignal: { _, curr, _ in
                guard let value = curr.candles[curr.index].technicalIndicators[rsiKey] else { return false }
                return value >= exit
            }
        )
    }

    /// Agentic preset: dual-anchor (VWAP + trend) slipstream continuation.
    func backtestDualAnchorSlipstream(candles: [Candlestick], trendPeriod: Int = 50) -> BacktestResult {
        guard candles.count > trendPeriod else { return bkEmptyBacktestResult() }
        let uuid = "dual_anchor_slipstream"
        let trendKey = "sma_\(trendPeriod)_\(uuid)"
        let vwapKey = "vwap_\(uuid)"
        let withTrend = simpleMovingAverage(candles, period: trendPeriod, name: trendKey)
        let enriched = vwap(withTrend, uuid: uuid)
        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let bar = curr.candles[curr.index]
                guard let trend = bar.technicalIndicators[trendKey], let anchor = bar.technicalIndicators[vwapKey] else { return false }
                return bar.close > trend && bar.close > anchor
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard let trend = bar.technicalIndicators[trendKey], let anchor = bar.technicalIndicators[vwapKey] else { return false }
                return bar.close < trend || bar.close < anchor
            }
        )
    }

    /// Agentic preset: trail directional pulses with ATR-gated exits.
    func backtestAtrPulseTrail(candles: [Candlestick], emaPeriod: Int = 21, atrPeriod: Int = 14) -> BacktestResult {
        guard candles.count > max(emaPeriod, atrPeriod) else { return bkEmptyBacktestResult() }
        let uuid = "atr_pulse_trail"
        let emaKey = "ema_\(emaPeriod)_\(uuid)"
        let atrKey = "atr_\(atrPeriod)_\(uuid)"
        let withAtr = averageTrueRange(candles, period: atrPeriod, uuid: uuid)
        let enriched = exponentialMovingAverage(withAtr, period: emaPeriod, uuid: uuid)
        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let bar = curr.candles[curr.index]
                guard let ema = bar.technicalIndicators[emaKey], let atr = bar.technicalIndicators[atrKey] else { return false }
                return bar.close > ema && (bar.high - bar.low) > atr * 0.9
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard let ema = bar.technicalIndicators[emaKey] else { return false }
                return bar.close < ema
            }
        )
    }

    /// Agentic preset: switch long-on slopes when fast and slow trend vectors align.
    func backtestSlopeSwitch(candles: [Candlestick], fastPeriod: Int = 10, slowPeriod: Int = 40) -> BacktestResult {
        guard candles.count > slowPeriod + 1 else { return bkEmptyBacktestResult() }
        let uuid = "slope_switch"
        let fastKey = "ema_\(fastPeriod)_\(uuid)"
        let slowKey = "sma_\(slowPeriod)_\(uuid)"
        let withFast = exponentialMovingAverage(candles, period: fastPeriod, uuid: uuid)
        let enriched = simpleMovingAverage(withFast, period: slowPeriod, name: slowKey)
        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let i = curr.index
                guard i > 0 else { return false }
                guard
                    let fast = curr.candles[i].technicalIndicators[fastKey],
                    let fastPrev = curr.candles[i - 1].technicalIndicators[fastKey],
                    let slow = curr.candles[i].technicalIndicators[slowKey],
                    let slowPrev = curr.candles[i - 1].technicalIndicators[slowKey]
                else { return false }
                return (fast - fastPrev) > 0 && (slow - slowPrev) > 0 && fast > slow
            },
            exitSignal: { _, curr, _ in
                let i = curr.index
                guard i > 0 else { return false }
                guard
                    let fast = curr.candles[i].technicalIndicators[fastKey],
                    let fastPrev = curr.candles[i - 1].technicalIndicators[fastKey]
                else { return false }
                return (fast - fastPrev) <= 0
            }
        )
    }

    /// Agentic preset: rebound into trend only when money-flow skew confirms.
    func backtestVolSkewRebound(candles: [Candlestick], mfiPeriod: Int = 10, trendPeriod: Int = 100) -> BacktestResult {
        guard candles.count > max(mfiPeriod, trendPeriod) else { return bkEmptyBacktestResult() }
        let uuid = "vol_skew_rebound"
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
                guard let mfi = bar.technicalIndicators[mfiKey], let trend = bar.technicalIndicators[trendKey] else { return false }
                return bar.close > trend && mfi < 35
            },
            exitSignal: { _, curr, _ in
                guard let mfi = curr.candles[curr.index].technicalIndicators[mfiKey] else { return false }
                return mfi > 60
            }
        )
    }

    /// Agentic preset: climb median band and exit on centerline failure.
    func backtestMedianBandClimb(candles: [Candlestick], period: Int = 30, std: Double = 1.5) -> BacktestResult {
        guard candles.count >= period else { return bkEmptyBacktestResult() }
        let uuid = "median_band_climb"
        let middleKey = "bbMiddle_\(period)_\(uuid)"
        let upperKey = "bbUpper_\(period)_\(std)_\(uuid)"
        let enriched = bollingerBands(candles, period: period, numStdDev: std, uuid: uuid)
        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let bar = curr.candles[curr.index]
                guard let middle = bar.technicalIndicators[middleKey], let upper = bar.technicalIndicators[upperKey] else { return false }
                return bar.close > middle && bar.close < upper
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard let middle = bar.technicalIndicators[middleKey] else { return false }
                return bar.close < middle
            }
        )
    }

    /// Agentic preset: snap back from stretched downside into short trend anchor.
    func backtestRangeSnapback(candles: [Candlestick], rangePeriod: Int = 15, emaPeriod: Int = 12) -> BacktestResult {
        guard candles.count > max(rangePeriod, emaPeriod) else { return bkEmptyBacktestResult() }
        let uuid = "range_snapback"
        let emaKey = "ema_\(emaPeriod)_\(uuid)"
        let enriched = exponentialMovingAverage(candles, period: emaPeriod, uuid: uuid)
        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let i = curr.index
                guard i >= rangePeriod else { return false }
                let bar = curr.candles[i]
                let low = curr.candles[(i - rangePeriod)..<i].map(\.low).min() ?? bar.low
                guard let ema = bar.technicalIndicators[emaKey] else { return false }
                return bar.close <= low * 1.01 && bar.close < ema
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard let ema = bar.technicalIndicators[emaKey] else { return false }
                return bar.close >= ema
            }
        )
    }

    /// Agentic preset: momentum valve opens on MACD positivity and closes on momentum decay.
    func backtestMomentumValve(candles: [Candlestick], fast: Int = 8, slow: Int = 21, signal: Int = 5) -> BacktestResult {
        guard candles.count > slow + signal else { return bkEmptyBacktestResult() }
        let uuid = "momentum_valve"
        let macdKey = "macd_\(fast)_\(slow)_\(uuid)"
        let signalKey = "macdSignal_\(signal)_\(uuid)"
        let enriched = macd(candles, fast: fast, slow: slow, signal: signal, uuid: uuid)
        return backtest(
            candles: enriched,
            uuid: uuid,
            indicators: [],
            entrySignal: { _, curr in
                let bar = curr.candles[curr.index]
                guard let macdValue = bar.technicalIndicators[macdKey], let signalValue = bar.technicalIndicators[signalKey] else { return false }
                return macdValue > signalValue && macdValue > 0
            },
            exitSignal: { _, curr, _ in
                let bar = curr.candles[curr.index]
                guard let macdValue = bar.technicalIndicators[macdKey], let signalValue = bar.technicalIndicators[signalKey] else { return false }
                return macdValue < signalValue
            }
        )
    }
}
