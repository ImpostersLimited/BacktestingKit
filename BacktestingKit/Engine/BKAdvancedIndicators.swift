import Foundation

public extension BacktestingKitManager {
    func averageTrueRange(_ candles: [Candlestick], period: Int, uuid: String) -> [Candlestick] {
        guard candles.count > 1, period > 0 else { return candles }
        var result = candles
        let key = "atr_\(period)_\(uuid)"

        var trueRanges: [Double] = Array(repeating: 0, count: candles.count)
        trueRanges[0] = candles[0].high - candles[0].low
        for i in 1..<candles.count {
            let highLow = candles[i].high - candles[i].low
            let highClose = abs(candles[i].high - candles[i - 1].close)
            let lowClose = abs(candles[i].low - candles[i - 1].close)
            trueRanges[i] = max(highLow, max(highClose, lowClose))
        }

        var atr = 0.0
        for i in 0..<candles.count {
            if i < period {
                atr += trueRanges[i]
                if i == period - 1 {
                    atr /= Double(period)
                    var ti = result[i].technicalIndicators
                    ti[key] = atr
                    result[i] = result[i].replacingTechnicalIndicators(ti)
                }
                continue
            }
            atr = ((atr * Double(period - 1)) + trueRanges[i]) / Double(period)
            var ti = result[i].technicalIndicators
            ti[key] = atr
            result[i] = result[i].replacingTechnicalIndicators(ti)
        }
        return result
    }

    func adx(_ candles: [Candlestick], period: Int, uuid: String) -> [Candlestick] {
        guard candles.count > period + 1, period > 0 else { return candles }
        var result = candles
        let adxKey = "adx_\(period)_\(uuid)"
        let plusDIKey = "plusDI_\(period)_\(uuid)"
        let minusDIKey = "minusDI_\(period)_\(uuid)"

        var tr: [Double] = Array(repeating: 0, count: candles.count)
        var plusDM: [Double] = Array(repeating: 0, count: candles.count)
        var minusDM: [Double] = Array(repeating: 0, count: candles.count)

        for i in 1..<candles.count {
            let upMove = candles[i].high - candles[i - 1].high
            let downMove = candles[i - 1].low - candles[i].low
            plusDM[i] = (upMove > downMove && upMove > 0) ? upMove : 0
            minusDM[i] = (downMove > upMove && downMove > 0) ? downMove : 0

            let highLow = candles[i].high - candles[i].low
            let highClose = abs(candles[i].high - candles[i - 1].close)
            let lowClose = abs(candles[i].low - candles[i - 1].close)
            tr[i] = max(highLow, max(highClose, lowClose))
        }

        var atr = tr[1...period].reduce(0, +)
        var smoothPlus = plusDM[1...period].reduce(0, +)
        var smoothMinus = minusDM[1...period].reduce(0, +)
        var dxValues: [Double] = []

        for i in (period + 1)..<candles.count {
            atr = atr - (atr / Double(period)) + tr[i]
            smoothPlus = smoothPlus - (smoothPlus / Double(period)) + plusDM[i]
            smoothMinus = smoothMinus - (smoothMinus / Double(period)) + minusDM[i]

            guard atr > 0 else { continue }
            let plusDI = 100 * (smoothPlus / atr)
            let minusDI = 100 * (smoothMinus / atr)
            let denominator = plusDI + minusDI
            let dx = denominator > 0 ? (100 * abs(plusDI - minusDI) / denominator) : 0
            dxValues.append(dx)

            var ti = result[i].technicalIndicators
            ti[plusDIKey] = plusDI
            ti[minusDIKey] = minusDI
            if dxValues.count == period {
                ti[adxKey] = dxValues.reduce(0, +) / Double(period)
            } else if dxValues.count > period, let prevAdx = result[i - 1].technicalIndicators[adxKey] {
                ti[adxKey] = ((prevAdx * Double(period - 1)) + dx) / Double(period)
            }
            result[i] = result[i].replacingTechnicalIndicators(ti)
        }
        return result
    }

    func stochasticOscillator(_ candles: [Candlestick], kPeriod: Int, dPeriod: Int, uuid: String) -> [Candlestick] {
        guard candles.count >= kPeriod, kPeriod > 0, dPeriod > 0 else { return candles }
        var result = candles
        let kKey = "stochK_\(kPeriod)_\(uuid)"
        let dKey = "stochD_\(dPeriod)_\(uuid)"
        var kSeries: [Double?] = Array(repeating: nil, count: candles.count)

        for i in (kPeriod - 1)..<candles.count {
            let window = candles[(i - kPeriod + 1)...i]
            let highest = window.map(\.high).max() ?? candles[i].high
            let lowest = window.map(\.low).min() ?? candles[i].low
            let denom = highest - lowest
            let k = denom > 0 ? ((candles[i].close - lowest) / denom) * 100 : 50
            kSeries[i] = k

            var ti = result[i].technicalIndicators
            ti[kKey] = k

            if i >= (kPeriod - 1 + dPeriod - 1) {
                let start = i - dPeriod + 1
                let dWindow = kSeries[start...i].compactMap { $0 }
                if dWindow.count == dPeriod {
                    ti[dKey] = dWindow.reduce(0, +) / Double(dPeriod)
                }
            }
            result[i] = result[i].replacingTechnicalIndicators(ti)
        }
        return result
    }

    func vwap(_ candles: [Candlestick], uuid: String) -> [Candlestick] {
        guard !candles.isEmpty else { return candles }
        var result = candles
        let key = "vwap_\(uuid)"
        var cumulativePV = 0.0
        var cumulativeVolume = 0.0

        for i in 0..<candles.count {
            let typical = (candles[i].high + candles[i].low + candles[i].close) / 3
            cumulativePV += typical * candles[i].volume
            cumulativeVolume += candles[i].volume
            let vwapValue = cumulativeVolume > 0 ? cumulativePV / cumulativeVolume : candles[i].close
            var ti = result[i].technicalIndicators
            ti[key] = vwapValue
            result[i] = result[i].replacingTechnicalIndicators(ti)
        }
        return result
    }

    func onBalanceVolume(_ candles: [Candlestick], uuid: String) -> [Candlestick] {
        guard !candles.isEmpty else { return candles }
        var result = candles
        let key = "obv_\(uuid)"
        var obv = 0.0

        for i in 0..<candles.count {
            if i > 0 {
                if candles[i].close > candles[i - 1].close {
                    obv += candles[i].volume
                } else if candles[i].close < candles[i - 1].close {
                    obv -= candles[i].volume
                }
            }
            var ti = result[i].technicalIndicators
            ti[key] = obv
            result[i] = result[i].replacingTechnicalIndicators(ti)
        }
        return result
    }

    func moneyFlowIndex(_ candles: [Candlestick], period: Int, uuid: String) -> [Candlestick] {
        guard candles.count > period, period > 0 else { return candles }
        var result = candles
        let key = "mfi_\(period)_\(uuid)"

        var rawMoneyFlow: [Double] = Array(repeating: 0, count: candles.count)
        var positiveFlow: [Double] = Array(repeating: 0, count: candles.count)
        var negativeFlow: [Double] = Array(repeating: 0, count: candles.count)
        let typicalPrices: [Double] = candles.map { ($0.high + $0.low + $0.close) / 3.0 }

        for i in 0..<candles.count {
            rawMoneyFlow[i] = typicalPrices[i] * candles[i].volume
            if i == 0 { continue }
            if typicalPrices[i] > typicalPrices[i - 1] {
                positiveFlow[i] = rawMoneyFlow[i]
            } else if typicalPrices[i] < typicalPrices[i - 1] {
                negativeFlow[i] = rawMoneyFlow[i]
            }
        }

        for i in period..<candles.count {
            let start = i - period + 1
            let pos = positiveFlow[start...i].reduce(0, +)
            let neg = negativeFlow[start...i].reduce(0, +)
            let mfi: Double
            if neg < Double.ulpOfOne, pos < Double.ulpOfOne {
                mfi = 50
            } else if neg < Double.ulpOfOne {
                mfi = 100
            } else if pos < Double.ulpOfOne {
                mfi = 0
            } else {
                let ratio = pos / neg
                mfi = 100 - (100 / (1 + ratio))
            }
            var ti = result[i].technicalIndicators
            ti[key] = mfi
            result[i] = result[i].replacingTechnicalIndicators(ti)
        }
        return result
    }
}
