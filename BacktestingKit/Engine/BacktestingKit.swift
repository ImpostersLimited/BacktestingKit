import Foundation

public final class BacktestingKitManager: BKBacktestingEngine {
    private let backtestMetricsCalculator: any BKBacktestMetricsCalculating

    /// Creates a new instance.
    public init() {
        self.backtestMetricsCalculator = BKBacktestMetricsCalculator()
    }

    init(backtestMetricsCalculator: any BKBacktestMetricsCalculating) {
        self.backtestMetricsCalculator = backtestMetricsCalculator
    }

    /// Calculates the Simple Moving Average (SMA) for the given candles and period.
    /// The 'name' parameter is required to uniquely key the SMA values in technicalIndicators.
    public func simpleMovingAverage(_ candles: [Candlestick], period: Int, name: String) -> [Candlestick] {
        guard candles.count >= period else { return candles }
        var result: [Candlestick] = candles
        var sum = 0.0
        for i in 0..<candles.count {
            sum += candles[i].close
            if i >= period {
                sum -= candles[i - period].close
            }
            if i >= period - 1 {
                let sma = sum / Double(period)
                var techInd = result[i].technicalIndicators
                techInd[name] = sma
                result[i] = result[i].replacingTechnicalIndicators(techInd)
            }
        }
        return result
    }

    /// Executes `buildMetricsReport`.
    public func buildMetricsReport(trades: [Trade], candles: [Candlestick]) -> BacktestMetricsReport {
        backtestMetricsCalculator.makeReport(trades: trades, candles: candles)
    }

    /// Executes `buildMetricsReport`.
    public func buildMetricsReport(from result: BacktestResult, candles: [Candlestick]) -> BacktestMetricsReport {
        buildMetricsReport(trades: result.trades, candles: candles)
    }

    /// Calculates the Exponential Moving Average (EMA) for the given candles and period.
    /// The 'uuid' parameter is required to uniquely key the EMA values in technicalIndicators.
    /// Stores EMA values in technicalIndicators under key "ema_{period}_{uuid}".
    public func exponentialMovingAverage(_ candles: [Candlestick], period: Int, uuid: String) -> [Candlestick] {
        guard candles.count >= period else { return candles }
        var result: [Candlestick] = candles
        let key = "ema_\(period)_\(uuid)"
        let k = 2.0 / Double(period + 1)
        var emaPrev: Double = candles[0].close

        for i in 0..<candles.count {
            let close = candles[i].close
            if i == 0 {
                emaPrev = close
            } else {
                emaPrev = close * k + emaPrev * (1 - k)
            }
            if i >= period - 1 {
                var techInd = result[i].technicalIndicators
                techInd[key] = emaPrev
                result[i] = result[i].replacingTechnicalIndicators(techInd)
            }
        }
        return result
    }

    /// Calculates the Relative Strength Index (RSI) for the given candles and period.
    /// The 'uuid' parameter is required to uniquely key the RSI values in technicalIndicators.
    /// RSI values range from 0 to 100 and are stored under key "rsi_{period}_{uuid}".
    public func relativeStrengthIndex(_ candles: [Candlestick], period: Int, uuid: String) -> [Candlestick] {
        guard candles.count >= period + 1 else { return candles }
        var result: [Candlestick] = candles
        let key = "rsi_\(period)_\(uuid)"

        var gains: [Double] = []
        var losses: [Double] = []

        for i in 1..<candles.count {
            let change = candles[i].close - candles[i-1].close
            if change > 0 {
                gains.append(change)
                losses.append(0)
            } else {
                gains.append(0)
                losses.append(-change)
            }
        }

        var avgGain = gains[0..<period].reduce(0, +) / Double(period)
        var avgLoss = losses[0..<period].reduce(0, +) / Double(period)

        for i in period..<gains.count {
            avgGain = (avgGain * Double(period - 1) + gains[i]) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + losses[i]) / Double(period)

            let rs = avgLoss == 0 ? 10000 : avgGain / avgLoss
            let rsi = 100 - (100 / (1 + rs))
            let idx = i + 1 // Because gains/losses start at candles[1]
            if idx < result.count {
                var techInd = result[idx].technicalIndicators
                techInd[key] = rsi
                result[idx] = result[idx].replacingTechnicalIndicators(techInd)
            }
        }
        return result
    }

    /// Calculates the MACD (Moving Average Convergence Divergence) indicator.
    /// The 'uuid' parameter is required to uniquely key the MACD values in technicalIndicators.
    /// Stores MACD line under "macd_{fast}_{slow}_{uuid}", Signal line under "macdSignal_{signal}_{uuid}", and Histogram under "macdHist_{fast}_{slow}_{signal}_{uuid}".
    public func macd(_ candles: [Candlestick], fast: Int, slow: Int, signal: Int, uuid: String) -> [Candlestick] {
        guard candles.count >= slow + signal else { return candles }
        var result: [Candlestick] = candles

        let fastEMA = exponentialMovingAverage(candles, period: fast, uuid: uuid)
        let slowEMA = exponentialMovingAverage(candles, period: slow, uuid: uuid)

        let macdKey = "macd_\(fast)_\(slow)_\(uuid)"
        let signalKey = "macdSignal_\(signal)_\(uuid)"
        let histKey = "macdHist_\(fast)_\(slow)_\(signal)_\(uuid)"

        // Compute MACD line (fastEMA - slowEMA)
        var macdLine: [Double?] = Array(repeating: nil, count: candles.count)
        for i in 0..<candles.count {
            let fastVal = fastEMA[i].technicalIndicators["ema_\(fast)_\(uuid)"]
            let slowVal = slowEMA[i].technicalIndicators["ema_\(slow)_\(uuid)"]
            if let f = fastVal, let s = slowVal {
                macdLine[i] = f - s
            } else {
                macdLine[i] = nil
            }
        }

        // Compute Signal line: EMA of MACD line with 'signal' period
        var signalLine: [Double?] = Array(repeating: nil, count: candles.count)
        // Find first index where macdLine is non-nil to start EMA calculation
        let firstMacdIndex = macdLine.firstIndex(where: {
            if case .some = $0 { return true }
            return false
        }) ?? 0

        // Calculate initial SMA for signal EMA start
        var emaSignalPrev: Double? = nil
        if macdLine.count >= firstMacdIndex + signal {
            let initialSlice = macdLine[firstMacdIndex..<(firstMacdIndex+signal)].compactMap { $0 }
            if initialSlice.count == signal {
                emaSignalPrev = initialSlice.reduce(0, +) / Double(signal)
                signalLine[firstMacdIndex + signal - 1] = emaSignalPrev
            }
        }

        let kSignal = 2.0 / Double(signal + 1)
        if let emaPrev = emaSignalPrev {
            var prev = emaPrev
            for i in (firstMacdIndex + signal)..<candles.count {
                if let macdVal = macdLine[i] {
                    let emaCurr = macdVal * kSignal + prev * (1 - kSignal)
                    signalLine[i] = emaCurr
                    prev = emaCurr
                } else {
                    signalLine[i] = nil
                }
            }
        }

        // Compute Histogram = MACD line - Signal line
        for i in 0..<candles.count {
            if let macdVal = macdLine[i], let signalVal = signalLine[i] {
                let hist = macdVal - signalVal
                var techInd = result[i].technicalIndicators
                techInd[macdKey] = macdVal
                techInd[signalKey] = signalVal
                techInd[histKey] = hist
                result[i] = result[i].replacingTechnicalIndicators(techInd)
            } else if let macdVal = macdLine[i] {
                var techInd = result[i].technicalIndicators
                techInd[macdKey] = macdVal
                result[i] = result[i].replacingTechnicalIndicators(techInd)
            }
        }

        return result
    }

    /// Calculates Bollinger Bands (Upper, Middle=SMA, Lower) for given period and std deviation multiplier.
    /// The 'uuid' parameter is required to uniquely key the Bollinger Bands values in technicalIndicators.
    /// Stores bands under keys "bbUpper_{period}_{numStdDev}_{uuid}", "bbMiddle_{period}_{uuid}", and "bbLower_{period}_{numStdDev}_{uuid}".
    public func bollingerBands(_ candles: [Candlestick], period: Int, numStdDev: Double, uuid: String) -> [Candlestick] {
        guard candles.count >= period else { return candles }
        var result: [Candlestick] = candles

        let middleKey = "bbMiddle_\(period)_\(uuid)"
        let upperKey = "bbUpper_\(period)_\(numStdDev)_\(uuid)"
        let lowerKey = "bbLower_\(period)_\(numStdDev)_\(uuid)"
        // Compatibility aliases for callers that use the longer key prefix.
        let middleAliasKey = "bollingerMiddle_\(period)_\(uuid)"
        let upperAliasKey = "bollingerUpper_\(period)_\(numStdDev)_\(uuid)"
        let lowerAliasKey = "bollingerLower_\(period)_\(numStdDev)_\(uuid)"

        var sum = 0.0
        var sumSq = 0.0

        for i in 0..<candles.count {
            let close = candles[i].close
            sum += close
            sumSq += close * close

            if i >= period {
                let oldClose = candles[i - period].close
                sum -= oldClose
                sumSq -= oldClose * oldClose
            }

            if i >= period - 1 {
                let mean = sum / Double(period)
                let variance = (sumSq / Double(period)) - (mean * mean)
                let stddev = variance > 0 ? sqrt(variance) : 0.0

                let upper = mean + numStdDev * stddev
                let lower = mean - numStdDev * stddev

                var techInd = result[i].technicalIndicators
                techInd[middleKey] = mean
                techInd[upperKey] = upper
                techInd[lowerKey] = lower
                techInd[middleAliasKey] = mean
                techInd[upperAliasKey] = upper
                techInd[lowerAliasKey] = lower

                result[i] = result[i].replacingTechnicalIndicators(techInd)
            }
        }

        return result
    }

    // SMA Crossover Backtest (classic: fast crosses slow upward = buy, downward = sell)
    // Now uses updated simpleMovingAverage returning [Candlestick] with embedded SMA values
    /// Executes `backtestSMACrossover`.
    public func backtestSMACrossover(candles: [Candlestick], fast: Int, slow: Int) -> BacktestResult {
        guard fast < slow, candles.count >= slow else {
            return backtestMetricsCalculator.emptyResult()
        }

        let uuid = "backtestSMA"
        let fastKey = "sma_\(fast)_\(uuid)"
        let slowKey = "sma_\(slow)_\(uuid)"
        let fastResult = simpleMovingAverage(candles, period: fast, name: fastKey)
        let slowResult = simpleMovingAverage(candles, period: slow, name: slowKey)
        let fastSMA = fastResult.map { $0.technicalIndicators[fastKey] }
        let slowSMA = slowResult.map { $0.technicalIndicators[slowKey] }

        var trades: [Trade] = []
        var inPosition = false
        var entryPrice: Double = 0
        var entryDate: Date = candles[0].date

        for i in 1..<candles.count {
            guard let fPrev = fastSMA[i-1], let sPrev = slowSMA[i-1],
                  let fCurr = fastSMA[i], let sCurr = slowSMA[i] else { continue }
            // Golden cross (buy signal)
            if !inPosition && fPrev < sPrev && fCurr >= sCurr {
                inPosition = true
                entryPrice = candles[i].close
                entryDate = candles[i].date
                trades.append(Trade(type: .buy, entryDate: entryDate, entryPrice: entryPrice))
            }
            // Death cross (sell signal)
            if inPosition && fPrev > sPrev && fCurr <= sCurr {
                inPosition = false
                let exitPrice = candles[i].close
                let exitDate = candles[i].date
                if let idx = trades.lastIndex(where: { $0.exitDate == nil }) {
                    let openTrade = trades[idx]
                    trades[idx] = Trade(type: openTrade.type, entryDate: openTrade.entryDate, entryPrice: openTrade.entryPrice, exitDate: exitDate, exitPrice: exitPrice)
                }
            }
        }
        // Close last open trade at end
        if inPosition, let last = candles.last {
            if let idx = trades.lastIndex(where: { $0.exitDate == nil }) {
                trades[idx] = Trade(type: trades[idx].type, entryDate: trades[idx].entryDate, entryPrice: trades[idx].entryPrice, exitDate: last.date, exitPrice: last.close)
            }
        }
        return backtestMetricsCalculator.makeResult(trades: trades, candles: candles)
    }

    /**
     General-purpose backtest: user supplies entry/exit logic using indicators and price by enum name.
     - Parameters:
       - candles: The candles.
       - uuid: Unique id for indicator calculations.
       - indicators: List of technical indicators to compute for this backtest.
       - entrySignal: Closure with (prev, curr) value providers; returns true to enter.
       - exitSignal: Closure with (prev, curr, entry) value providers; returns true to exit.
    */
    /// Executes `backtest`.
    public func backtest(
        candles: [Candlestick],
        uuid: String,
        indicators: [TechnicalIndicator],
        entrySignal: (_ prev: TechnicalIndicatorValueProvider, _ curr: TechnicalIndicatorValueProvider) -> Bool,
        exitSignal: (_ prev: TechnicalIndicatorValueProvider, _ curr: TechnicalIndicatorValueProvider, _ entry: TechnicalIndicatorValueProvider) -> Bool
    ) -> BacktestResult {
        guard candles.count > 1 else {
            return backtestMetricsCalculator.emptyResult()
        }
        var enriched = candles
        // Compute all requested indicators for all candles
        for indicator in indicators {
            switch indicator {
            case .sma(let period):
                let key = "sma_\(period)_\(uuid)"
                enriched = simpleMovingAverage(enriched, period: period, name: key)
            }
        }
        var trades: [Trade] = []
        var inPosition = false
        var entryPrice: Double = 0
        var entryDate: Date = candles[0].date
        var entryIdx = 0
        for i in 1..<enriched.count {
            let prevProvider = TechnicalIndicatorValueProvider(index: i-1, candles: enriched, indicatorNameMap: [:])
            let currProvider = TechnicalIndicatorValueProvider(index: i, candles: enriched, indicatorNameMap: [:])
            if !inPosition && entrySignal(prevProvider, currProvider) {
                inPosition = true
                entryPrice = enriched[i].close
                entryDate = enriched[i].date
                entryIdx = i
                trades.append(Trade(type: .buy, entryDate: entryDate, entryPrice: entryPrice))
            } else if inPosition {
                let entryProvider = TechnicalIndicatorValueProvider(index: entryIdx, candles: enriched, indicatorNameMap: [:])
                if exitSignal(prevProvider, currProvider, entryProvider) {
                    inPosition = false
                    let exitPrice = enriched[i].close
                    let exitDate = enriched[i].date
                    if let idx = trades.lastIndex(where: { $0.exitDate == nil }) {
                        let openTrade = trades[idx]
                        trades[idx] = Trade(type: openTrade.type, entryDate: openTrade.entryDate, entryPrice: openTrade.entryPrice, exitDate: exitDate, exitPrice: exitPrice)
                    }
                }
            }
        }
        // Close last open trade at end
        if inPosition, let last = enriched.last {
            if let idx = trades.lastIndex(where: { $0.exitDate == nil }) {
                trades[idx] = Trade(type: trades[idx].type, entryDate: trades[idx].entryDate, entryPrice: trades[idx].entryPrice, exitDate: last.date, exitPrice: last.close)
            }
        }
        return backtestMetricsCalculator.makeResult(trades: trades, candles: candles)
    }

    /**
     Backtest with declarative entry/exit conditions.
     - Parameters:
       - candles: Candles.
       - uuid: Unique id for indicator calculations.
       - indicators: Indicators to compute.
       - entryConditions: All must be true to enter.
       - exitConditions: All must be true to exit.
     */
    /// Executes `backtest`.
    public func backtest(
        candles: [Candlestick],
        indicators: [(name: String, indicator: TechnicalIndicator)],
        entryConditions: [StrategyCondition],
        exitConditions: [StrategyCondition]
    ) -> BacktestResult {
        var indicatorNameMap: [TechnicalIndicator: String] = [:]
        for (name, indicator) in indicators {
            indicatorNameMap[indicator] = name
        }
        var enriched = candles
        // Compute all requested indicators for all candles
        for (name, indicator) in indicators {
            switch indicator {
            case .sma(let period):
                enriched = simpleMovingAverage(enriched, period: period, name: name)
            }
        }
        func eval(_ cond: StrategyCondition, curr: TechnicalIndicatorValueProvider) -> Bool {
            func val(_ op: StrategyOperand, p: TechnicalIndicatorValueProvider) -> Double? {
                switch op {
                case .indicator(let ti): return p.value(for: ti)
                case .price(let pt): return p.price(pt)
                case .constant(let d): return d
                }
            }
            let lCurr = val(cond.lhs, p: curr)
            let rCurr = val(cond.rhs, p: curr)

            switch cond.op {
            case .greaterThan:
                if let l = lCurr, let r = rCurr { return l > r }
            case .lessThan:
                if let l = lCurr, let r = rCurr { return l < r }
            case .greaterThanOrEqual:
                if let l = lCurr, let r = rCurr { return l >= r }
            case .lessThanOrEqual:
                if let l = lCurr, let r = rCurr { return l <= r }
            }
            return false
        }
        return self.backtest(
            candles: enriched,
            uuid: "",
            indicators: indicators.map { $0.indicator },
            entrySignal: { prev, curr in
                let currProvider = TechnicalIndicatorValueProvider(index: curr.index, candles: curr.candles, indicatorNameMap: indicatorNameMap)
                return entryConditions.allSatisfy { eval($0, curr: currProvider) }
            },
            exitSignal: { prev, curr, entry in
                let currProvider = TechnicalIndicatorValueProvider(index: curr.index, candles: curr.candles, indicatorNameMap: indicatorNameMap)
                return exitConditions.allSatisfy { eval($0, curr: currProvider) }
            }
        )
    }
}
