import Foundation

public enum TechnicalIndicator: Hashable, Identifiable, Equatable, Codable, CustomStringConvertible, CaseIterable {
    case sma(period: Int)
    
    public static var allCases: [TechnicalIndicator] {
        // Only representative cases without associated values
        // (users can extend as needed)
        [.sma(period: 0)]
    }
    public var id: Int {
        switch self {
        case .sma(let period): return period.hashValue ^ 0x1000
        }
    }
    public var description: String {
        switch self {
        case .sma(let period): return "SMA(\(period))"
        }
    }
}

public enum StrategyOperand: Hashable, Identifiable, Equatable, Codable, CustomStringConvertible, CaseIterable {
    case indicator(TechnicalIndicator)
    case price(TechnicalIndicatorValueProvider.PriceType)
    case constant(Double)

    public static var allCases: [StrategyOperand] {
        [.indicator(.sma(period: 0)), .price(.open), .constant(0)]
    }
    public var id: Int {
        switch self {
        case .indicator(let ti): return ti.id ^ 0x2000
        case .price(let pt): return pt.id ^ 0x2100
        case .constant(let d): return Int(truncatingIfNeeded: d.bitPattern)
        }
    }
    public var description: String {
        switch self {
        case .indicator(let ti): return "Indicator(\(ti))"
        case .price(let pt): return "Price(\(pt))"
        case .constant(let d): return "Constant(\(d))"
        }
    }
}

public enum StrategyOperator: Hashable, Identifiable, Equatable, Codable, CustomStringConvertible, CaseIterable {
    case greaterThan
    case lessThan
    case greaterThanOrEqual
    case lessThanOrEqual
    public static var allCases: [StrategyOperator] {
        [.greaterThan, .lessThan, .greaterThanOrEqual, .lessThanOrEqual]
    }
    public var id: Int {
        switch self {
        case .greaterThan: return 0
        case .lessThan: return 1
        case .greaterThanOrEqual: return 2
        case .lessThanOrEqual: return 3
        }
    }
    public var description: String {
        switch self {
        case .greaterThan: return ">"
        case .lessThan: return "<"
        case .greaterThanOrEqual: return ">="
        case .lessThanOrEqual: return "<="
        }
    }
}

// Nested enum
extension TechnicalIndicatorValueProvider.PriceType: Hashable, Identifiable, Equatable, Codable, CustomStringConvertible, CaseIterable {
    public static var allCases: [Self] { [.open, .high, .low, .close, .volume] }
    public var id: Int { self.hashValue }
    public var description: String {
        switch self {
        case .open: return "Open"
        case .high: return "High"
        case .low: return "Low"
        case .close: return "Close"
        case .volume: return "Volume"
        }
    }
}

public struct StrategyCondition: Hashable, Identifiable, Equatable, Codable {
    public let lhs: StrategyOperand
    public let op: StrategyOperator
    public let rhs: StrategyOperand
    public init(_ lhs: StrategyOperand, _ op: StrategyOperator, _ rhs: StrategyOperand) {
        self.lhs = lhs
        self.op = op
        self.rhs = rhs
    }
    public var id: Int { lhs.id ^ op.id ^ rhs.id }
}

public struct TechnicalIndicatorValueProvider: Identifiable, Equatable, Codable {
    public let index: Int
    public let candles: [Candlestick]
    public let indicatorNameMap: [TechnicalIndicator: String]
    public func value(for indicator: TechnicalIndicator) -> Double? {
        guard let name = indicatorNameMap[indicator] else { return nil }
        return candles[index].technicalIndicators[name]
    }
    public func price(_ type: PriceType) -> Double {
        let candle = candles[index]
        switch type {
        case .open: return candle.open
        case .high: return candle.high
        case .low: return candle.low
        case .close: return candle.close
        case .volume: return candle.volume
        }
    }
    public enum PriceType { case open, high, low, close, volume }
    public var id: Int { index }
}

public class BacktestingKitManager {
    public init() {}
    
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
                result[i] = Candlestick(date: result[i].date, open: result[i].open, high: result[i].high, low: result[i].low, close: result[i].close, volume: result[i].volume, technicalIndicators: techInd)
            }
        }
        return result
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
                result[i] = Candlestick(date: result[i].date, open: result[i].open, high: result[i].high, low: result[i].low, close: result[i].close, volume: result[i].volume, technicalIndicators: techInd)
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
                result[idx] = Candlestick(date: result[idx].date, open: result[idx].open, high: result[idx].high, low: result[idx].low, close: result[idx].close, volume: result[idx].volume, technicalIndicators: techInd)
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
            if let fastVal = fastEMA[i].technicalIndicators[macdKey] ?? fastEMA[i].technicalIndicators["ema_\(fast)_\(uuid)"],
               let slowVal = slowEMA[i].technicalIndicators[macdKey] ?? slowEMA[i].technicalIndicators["ema_\(slow)_\(uuid)"] {
                macdLine[i] = fastVal - slowVal
            } else {
                let fVal = fastEMA[i].technicalIndicators["ema_\(fast)_\(uuid)"]
                let sVal = slowEMA[i].technicalIndicators["ema_\(slow)_\(uuid)"]
                if let f = fVal, let s = sVal {
                    macdLine[i] = f - s
                } else {
                    macdLine[i] = nil
                }
            }
        }
        
        // Compute Signal line: EMA of MACD line with 'signal' period
        var signalLine: [Double?] = Array(repeating: nil, count: candles.count)
        // Find first index where macdLine is non-nil to start EMA calculation
        let firstMacdIndex = macdLine.firstIndex(where: { $0 != nil }) ?? 0
        
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
                result[i] = Candlestick(date: result[i].date, open: result[i].open, high: result[i].high, low: result[i].low, close: result[i].close, volume: result[i].volume, technicalIndicators: techInd)
            } else if let macdVal = macdLine[i] {
                var techInd = result[i].technicalIndicators
                techInd[macdKey] = macdVal
                result[i] = Candlestick(date: result[i].date, open: result[i].open, high: result[i].high, low: result[i].low, close: result[i].close, volume: result[i].volume, technicalIndicators: techInd)
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
                
                result[i] = Candlestick(date: result[i].date, open: result[i].open, high: result[i].high, low: result[i].low, close: result[i].close, volume: result[i].volume, technicalIndicators: techInd)
            }
        }
        
        return result
    }
    
    // SMA Crossover Backtest (classic: fast crosses slow upward = buy, downward = sell)
    // Now uses updated simpleMovingAverage returning [Candlestick] with embedded SMA values
    public func backtestSMACrossover(candles: [Candlestick], fast: Int, slow: Int) -> BacktestResult {
        guard fast < slow, candles.count >= slow else {
            return BacktestResult(trades: [],
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
                                  ulcerIndex: 0)
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
        // Performance metrics
        var totalReturn = 0.0
        var wins = 0
        var losses = 0
        var tradeReturns: [Double] = []
        var equityCurve: [Double] = []
        var cumulativeReturn = 0.0
        
        for trade in trades {
            if let exit = trade.exitPrice {
                let r = (exit - trade.entryPrice) / trade.entryPrice
                totalReturn += r
                tradeReturns.append(r)
                cumulativeReturn += r
                equityCurve.append(cumulativeReturn)
                if r > 0 {
                    wins += 1
                } else if r < 0 {
                    losses += 1
                }
            }
        }
        
        let numTrades = tradeReturns.count
        let numWins = wins
        let numLosses = losses
        let avgTradeReturn = numTrades > 0 ? tradeReturns.reduce(0, +) / Double(numTrades) : 0
        
        // Calculate maximum drawdown on equity curve
        var maxDrawdown = 0.0
        var peak = 0.0
        for value in equityCurve {
            if value > peak {
                peak = value
            }
            let drawdown = peak - value
            if drawdown > maxDrawdown {
                maxDrawdown = drawdown
            }
        }
        
        // Sharpe Ratio calculation assuming risk-free rate = 0
        // Annualize by sqrt of number of trades (assuming trades represent independent periods)
        let meanReturn = avgTradeReturn
        let stdDevReturn = numTrades > 1 ? sqrt(tradeReturns.reduce(0) { $0 + ($1 - meanReturn) * ($1 - meanReturn) } / Double(numTrades - 1)) : 0
        let sharpeRatio = (stdDevReturn > 0 && numTrades > 0) ? (meanReturn / stdDevReturn) * sqrt(Double(numTrades)) : 0
        
        // Profit Factor = sum of wins / absolute sum of losses
        let sumWins = tradeReturns.filter { $0 > 0 }.reduce(0, +)
        let sumLosses = tradeReturns.filter { $0 < 0 }.reduce(0, +)
        let profitFactor = (sumLosses != 0) ? (sumWins / abs(sumLosses)) : 0
        
        // Expectancy = (probability win * avg win) + (probability loss * avg loss)
        let probWin = numTrades > 0 ? Double(numWins) / Double(numTrades) : 0
        let probLoss = numTrades > 0 ? Double(numLosses) / Double(numTrades) : 0
        let avgWin = numWins > 0 ? tradeReturns.filter { $0 > 0 }.reduce(0, +) / Double(numWins) : 0
        let avgLoss = numLosses > 0 ? tradeReturns.filter { $0 < 0 }.reduce(0, +) / Double(numLosses) : 0
        let expectancy = probWin * avgWin + probLoss * avgLoss
        
        let winRate = trades.isEmpty ? 0 : Double(numWins) / Double(trades.count)
        
        // Annualized return estimation
        let days = candles.count > 1 ? Calendar.current.dateComponents([.day], from: candles.first!.date, to: candles.last!.date).day ?? 0 : 0
        let years = days > 0 ? Double(days) / 365.0 : 1
        let annReturn = years > 0 ? pow(1.0 + totalReturn, 1.0 / years) - 1.0 : 0
        
        return BacktestResult(trades: trades,
                              totalReturn: totalReturn,
                              annualizedReturn: annReturn,
                              winRate: winRate,
                              maxDrawdown: maxDrawdown,
                              sharpeRatio: sharpeRatio,
                              avgTradeReturn: avgTradeReturn,
                              numTrades: numTrades,
                              numWins: numWins,
                              numLosses: numLosses,
                              profitFactor: profitFactor,
                              expectancy: expectancy,
                              cagr: 0,
                              volatility: 0,
                              sortinoRatio: 0,
                              calmarRatio: 0,
                              avgHoldingPeriod: 0,
                              maxConsecutiveWins: 0,
                              maxConsecutiveLosses: 0,
                              avgWin: avgWin,
                              avgLoss: avgLoss,
                              kellyCriterion: 0,
                              ulcerIndex: 0)
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
    public func backtest(
        candles: [Candlestick],
        uuid: String,
        indicators: [TechnicalIndicator],
        entrySignal: (_ prev: TechnicalIndicatorValueProvider, _ curr: TechnicalIndicatorValueProvider) -> Bool,
        exitSignal: (_ prev: TechnicalIndicatorValueProvider, _ curr: TechnicalIndicatorValueProvider, _ entry: TechnicalIndicatorValueProvider) -> Bool
    ) -> BacktestResult {
        guard candles.count > 1 else {
            return BacktestResult(trades: [], totalReturn: 0, annualizedReturn: 0, winRate: 0, maxDrawdown: 0, sharpeRatio: 0, avgTradeReturn: 0, numTrades: 0, numWins: 0, numLosses: 0, profitFactor: 0, expectancy: 0, cagr: 0, volatility: 0, sortinoRatio: 0, calmarRatio: 0, avgHoldingPeriod: 0, maxConsecutiveWins: 0, maxConsecutiveLosses: 0, avgWin: 0, avgLoss: 0, kellyCriterion: 0, ulcerIndex: 0)
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
        var totalReturn = 0.0
        var wins = 0
        var losses = 0
        var tradeReturns: [Double] = []
        var equityCurve: [Double] = []
        var cumulativeReturn = 0.0
        for trade in trades {
            if let exit = trade.exitPrice {
                let r = (exit - trade.entryPrice) / trade.entryPrice
                totalReturn += r
                tradeReturns.append(r)
                cumulativeReturn += r
                equityCurve.append(cumulativeReturn)
                if r > 0 {
                    wins += 1
                } else if r < 0 {
                    losses += 1
                }
            }
        }
        let numTrades = tradeReturns.count
        let numWins = wins
        let numLosses = losses
        let avgTradeReturn = numTrades > 0 ? tradeReturns.reduce(0, +) / Double(numTrades) : 0
        var maxDrawdown = 0.0
        var peak = 0.0
        for value in equityCurve {
            if value > peak { peak = value }
            let drawdown = peak - value
            if drawdown > maxDrawdown { maxDrawdown = drawdown }
        }
        let meanReturn = avgTradeReturn
        let stdDevReturn = numTrades > 1 ? sqrt(tradeReturns.reduce(0) { $0 + ($1 - meanReturn) * ($1 - meanReturn) } / Double(numTrades - 1)) : 0
        let sharpeRatio = (stdDevReturn > 0 && numTrades > 0) ? (meanReturn / stdDevReturn) * sqrt(Double(numTrades)) : 0
        let sumWins = tradeReturns.filter { $0 > 0 }.reduce(0, +)
        let sumLosses = tradeReturns.filter { $0 < 0 }.reduce(0, +)
        let profitFactor = (sumLosses != 0) ? (sumWins / abs(sumLosses)) : 0
        let probWin = numTrades > 0 ? Double(numWins) / Double(numTrades) : 0
        let probLoss = numTrades > 0 ? Double(numLosses) / Double(numTrades) : 0
        let avgWin = numWins > 0 ? tradeReturns.filter { $0 > 0 }.reduce(0, +) / Double(numWins) : 0
        let avgLoss = numLosses > 0 ? tradeReturns.filter { $0 < 0 }.reduce(0, +) / Double(numLosses) : 0
        let expectancy = probWin * avgWin + probLoss * avgLoss
        let winRate = trades.isEmpty ? 0 : Double(numWins) / Double(trades.count)
        let days = candles.count > 1 ? Calendar.current.dateComponents([.day], from: candles.first!.date, to: candles.last!.date).day ?? 0 : 0
        let years = days > 0 ? Double(days) / 365.0 : 1
        let annReturn = years > 0 ? pow(1.0 + totalReturn, 1.0 / years) - 1.0 : 0
        return BacktestResult(trades: trades,
                              totalReturn: totalReturn,
                              annualizedReturn: annReturn,
                              winRate: winRate,
                              maxDrawdown: maxDrawdown,
                              sharpeRatio: sharpeRatio,
                              avgTradeReturn: avgTradeReturn,
                              numTrades: numTrades,
                              numWins: numWins,
                              numLosses: numLosses,
                              profitFactor: profitFactor,
                              expectancy: expectancy,
                              cagr: 0,
                              volatility: 0,
                              sortinoRatio: 0,
                              calmarRatio: 0,
                              avgHoldingPeriod: 0,
                              maxConsecutiveWins: 0,
                              maxConsecutiveLosses: 0,
                              avgWin: avgWin,
                              avgLoss: avgLoss,
                              kellyCriterion: 0,
                              ulcerIndex: 0)
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
