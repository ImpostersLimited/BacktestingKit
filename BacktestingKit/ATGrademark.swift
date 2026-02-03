import Foundation

public enum TradeDirection: String, Codable {
    case long
    case short
}

public enum PositionStatus: String, Codable {
    case enter = "Enter"
    case none = "None"
    case position = "Position"
    case exit = "Exit"
}

public struct ATBar: Codable, Equatable {
    public var time: Date
    public var open: Double
    public var high: Double
    public var low: Double
    public var close: Double
    public var volume: Double
    public var indicators: [String: Double]

    public init(time: Date, open: Double, high: Double, low: Double, close: Double, volume: Double, indicators: [String: Double] = [:]) {
        self.time = time
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.indicators = indicators
    }

    public func value(forName name: String) -> Double? {
        switch name {
        case "open": return open
        case "high": return high
        case "low": return low
        case "close": return close
        case "volume": return volume
        default: return indicators[name]
        }
    }
}

public struct ATBacktestOptions {
    public var recordStopPrice: Bool
    public var recordRisk: Bool

    public init(recordStopPrice: Bool = false, recordRisk: Bool = false) {
        self.recordStopPrice = recordStopPrice
        self.recordRisk = recordRisk
    }
}

public struct ATPosition {
    public var direction: TradeDirection
    public var entryTime: Date
    public var entryPrice: Double
    public var profit: Double
    public var profitPct: Double
    public var growth: Double
    public var initialUnitRisk: Double?
    public var initialRiskPct: Double?
    public var curRiskPct: Double?
    public var curRMultiple: Double?
    public var riskSeries: [ATTimestampedValue]?
    public var holdingPeriod: Int
    public var initialStopPrice: Double?
    public var curStopPrice: Double?
    public var stopPriceSeries: [ATTimestampedValue]?
    public var profitTarget: Double?
}

public struct GMTrade: Codable, Equatable {
    public var direction: TradeDirection
    public var entryTime: Date
    public var entryPrice: Double
    public var exitTime: Date
    public var exitPrice: Double
    public var profit: Double
    public var profitPct: Double
    public var growth: Double
    public var riskPct: Double?
    public var rmultiple: Double?
    public var riskSeries: [ATTimestampedValue]?
    public var holdingPeriod: Int
    public var exitReason: String
    public var stopPrice: Double?
    public var stopPriceSeries: [ATTimestampedValue]?
    public var profitTarget: Double?
}

public struct GMAnalysis: Codable, Equatable {
    public var startingCapital: Double
    public var finalCapital: Double
    public var profit: Double
    public var profitPct: Double
    public var growth: Double
    public var totalTrades: Int
    public var barCount: Int
    public var maxDrawdown: Double
    public var maxDrawdownPct: Double
    public var maxRiskPct: Double?
    public var expectency: Double
    public var rmultipleStdDev: Double
    public var systemQuality: Double?
    public var profitFactor: Double?
    public var proportionProfitable: Double
    public var percentProfitable: Double
    public var returnOnAccount: Double
    public var averageProfitPerTrade: Double
    public var numWinningTrades: Int
    public var numLosingTrades: Int
    public var averageWinningTrade: Double
    public var averageLosingTrade: Double
    public var expectedValue: Double
}

public typealias EnterPositionFn = (_ options: ATEnterPositionOptions?) -> Void
public typealias ExitPositionFn = () -> Void

public struct ATEnterPositionOptions {
    public var direction: TradeDirection?
    public var entryPrice: Double?

    public init(direction: TradeDirection? = nil, entryPrice: Double? = nil) {
        self.direction = direction
        self.entryPrice = entryPrice
    }
}

public struct ATRuleParams {
    public var bar: ATBar
    public var lookback: [ATBar]
    public var parameters: [String: Double]

    public init(bar: ATBar, lookback: [ATBar], parameters: [String: Double]) {
        self.bar = bar
        self.lookback = lookback
        self.parameters = parameters
    }
}

public struct ATOpenPositionRuleArgs {
    public var entryPrice: Double
    public var position: ATPosition
    public var bar: ATBar
    public var lookback: [ATBar]
    public var parameters: [String: Double]
}

public typealias ATEntryRuleFn = (_ enterPosition: EnterPositionFn, _ args: ATRuleParams) -> Void
public typealias ATExitRuleFn = (_ exitPosition: ExitPositionFn, _ args: ATOpenPositionRuleArgs) -> Void
public typealias ATStopLossFn = (_ args: ATOpenPositionRuleArgs) -> Double
public typealias ATProfitTargetFn = (_ args: ATOpenPositionRuleArgs) -> Double

public struct ATStrategy {
    public var parameters: [String: Double]
    public var lookbackPeriod: Int
    public var prepIndicators: ((_ input: [ATBar], _ parameters: [String: Double]) -> [ATBar])?
    public var entryRule: ATEntryRuleFn
    public var exitRule: ATExitRuleFn?
    public var stopLoss: ATStopLossFn?
    public var trailingStopLoss: ATStopLossFn?
    public var profitTarget: ATProfitTargetFn?

    public init(
        parameters: [String: Double] = [:],
        lookbackPeriod: Int = 1,
        prepIndicators: ((_ input: [ATBar], _ parameters: [String: Double]) -> [ATBar])? = nil,
        entryRule: @escaping ATEntryRuleFn,
        exitRule: ATExitRuleFn? = nil,
        stopLoss: ATStopLossFn? = nil,
        trailingStopLoss: ATStopLossFn? = nil,
        profitTarget: ATProfitTargetFn? = nil
    ) {
        self.parameters = parameters
        self.lookbackPeriod = lookbackPeriod
        self.prepIndicators = prepIndicators
        self.entryRule = entryRule
        self.exitRule = exitRule
        self.stopLoss = stopLoss
        self.trailingStopLoss = trailingStopLoss
        self.profitTarget = profitTarget
    }
}

private struct LookbackBuffer<T> {
    private var buffer: [T?]
    private var head: Int = 0
    private var count: Int = 0
    private let capacity: Int

    init(capacity: Int) {
        self.capacity = max(capacity, 1)
        self.buffer = Array(repeating: nil, count: self.capacity)
    }

    mutating func push(_ value: T) {
        if count < capacity {
            buffer[count] = value
            count += 1
        } else {
            buffer[head] = value
            head = (head + 1) % capacity
        }
    }

    func toArray() -> [T] {
        if count < capacity {
            return buffer.prefix(count).compactMap { $0 }
        }
        var result: [T] = []
        result.reserveCapacity(capacity)
        for i in 0..<capacity {
            let idx = (head + i) % capacity
            if let value = buffer[idx] {
                result.append(value)
            }
        }
        return result
    }

    var length: Int {
        return count
    }
}

private func updatePosition(_ position: inout ATPosition, _ bar: ATBar) {
    position.profit = bar.close - position.entryPrice
    position.profitPct = (position.profit / position.entryPrice) * 100
    position.growth = position.direction == .long
        ? bar.close / position.entryPrice
        : position.entryPrice / bar.close
    if let curStop = position.curStopPrice {
        let unitRisk = position.direction == .long
            ? bar.close - curStop
            : curStop - bar.close
        position.curRiskPct = (unitRisk / bar.close) * 100
        position.curRMultiple = position.profit / unitRisk
    }
    position.holdingPeriod += 1
}

private func finalizePosition(_ position: ATPosition, exitTime: Date, exitPrice: Double, exitReason: String) -> ATTrade {
    let profit = position.direction == .long
        ? exitPrice - position.entryPrice
        : position.entryPrice - exitPrice
    let rmultiple: Double
    if let unitRisk = position.initialUnitRisk, unitRisk != 0 {
        rmultiple = profit / unitRisk
    } else {
        rmultiple = 0
    }
    return ATTrade(
        direction: position.direction,
        entryTime: position.entryTime,
        entryPrice: position.entryPrice,
        exitTime: exitTime,
        exitPrice: exitPrice,
        profit: profit,
        profitPct: (profit / position.entryPrice) * 100,
        growth: position.direction == .long
            ? exitPrice / position.entryPrice
            : position.entryPrice / exitPrice,
        riskPct: position.initialRiskPct ?? 0,
        rmultiple: rmultiple,
        riskSeries: position.riskSeries ?? [],
        holdingPeriod: position.holdingPeriod,
        exitReason: exitReason,
        stopPrice: position.initialStopPrice ?? 0,
        stopPriceSeries: position.stopPriceSeries ?? [],
        profitTarget: position.profitTarget ?? 0
    )
}

public func backtest(
    strategy: ATStrategy,
    inputSeries: [ATBar],
    options: ATBacktestOptions = ATBacktestOptions()
) -> (trades: [ATTrade], lastStatus: PositionStatus) {
    guard inputSeries.count > 0 else {
        return ([], .none)
    }

    let lookbackPeriod = max(strategy.lookbackPeriod, 1)
    if inputSeries.count < lookbackPeriod {
        return ([], .none)
    }

    let strategyParameters = strategy.parameters
    let indicatorsSeries = strategy.prepIndicators?(inputSeries, strategyParameters) ?? inputSeries

    var completedTrades: [ATTrade] = []
    var positionStatus: PositionStatus = .none
    var positionDirection: TradeDirection = .long
    var conditionalEntryPrice: Double?
    var openPosition: ATPosition?

    var lookbackBuffer = LookbackBuffer<ATBar>(capacity: lookbackPeriod)

    func enterPosition(_ options: ATEnterPositionOptions?) {
        guard positionStatus == .none else { return }
        positionStatus = .enter
        positionDirection = options?.direction ?? .long
        conditionalEntryPrice = options?.entryPrice
    }

    func exitPosition() {
        guard positionStatus == .position else { return }
        positionStatus = .exit
    }

    func closePosition(_ bar: ATBar, _ exitPrice: Double, _ exitReason: String) {
        if let open = openPosition {
            let trade = finalizePosition(open, exitTime: bar.time, exitPrice: exitPrice, exitReason: exitReason)
            completedTrades.append(trade)
        }
        openPosition = nil
        positionStatus = .none
    }

    for bar in indicatorsSeries {
        lookbackBuffer.push(bar)
        if lookbackBuffer.length < lookbackPeriod {
            continue
        }
        let lookback = lookbackBuffer.toArray()

        switch positionStatus {
        case .none:
            strategy.entryRule(enterPosition, ATRuleParams(bar: bar, lookback: lookback, parameters: strategyParameters))
        case .enter:
            if conditionalEntryPrice != nil {
                if positionDirection == .long {
                    if bar.high < (conditionalEntryPrice ?? 0) { break }
                } else {
                    if bar.low > (conditionalEntryPrice ?? 0) { break }
                }
            }

            let entryPrice = bar.open
            var newPosition = ATPosition(
                direction: positionDirection,
                entryTime: bar.time,
                entryPrice: entryPrice,
                profit: 0,
                profitPct: 0,
                growth: 1,
                holdingPeriod: 0
            )

            if let stopLoss = strategy.stopLoss {
                let stopDistance = stopLoss(ATOpenPositionRuleArgs(
                    entryPrice: entryPrice,
                    position: newPosition,
                    bar: bar,
                    lookback: lookback,
                    parameters: strategyParameters
                ))
                newPosition.initialStopPrice = newPosition.direction == .long
                    ? entryPrice - stopDistance
                    : entryPrice + stopDistance
                newPosition.curStopPrice = newPosition.initialStopPrice
            }

            if let trailingStopLoss = strategy.trailingStopLoss {
                let trailingStopDistance = trailingStopLoss(ATOpenPositionRuleArgs(
                    entryPrice: entryPrice,
                    position: newPosition,
                    bar: bar,
                    lookback: lookback,
                    parameters: strategyParameters
                ))
                let trailingStopPrice = newPosition.direction == .long
                    ? entryPrice - trailingStopDistance
                    : entryPrice + trailingStopDistance
                if newPosition.initialStopPrice == nil {
                    newPosition.initialStopPrice = trailingStopPrice
                } else if newPosition.direction == .long {
                    newPosition.initialStopPrice = max(newPosition.initialStopPrice ?? trailingStopPrice, trailingStopPrice)
                } else {
                    newPosition.initialStopPrice = min(newPosition.initialStopPrice ?? trailingStopPrice, trailingStopPrice)
                }
                newPosition.curStopPrice = newPosition.initialStopPrice
                if options.recordStopPrice {
                    newPosition.stopPriceSeries = [
                        ATTimestampedValue(time: bar.time, value: newPosition.curStopPrice ?? 0)
                    ]
                }
            }

            if let curStop = newPosition.curStopPrice {
                newPosition.initialUnitRisk = newPosition.direction == .long
                    ? entryPrice - curStop
                    : curStop - entryPrice
                newPosition.initialRiskPct = (newPosition.initialUnitRisk ?? 0) / entryPrice * 100
                newPosition.curRiskPct = newPosition.initialRiskPct
                newPosition.curRMultiple = 0
                if options.recordRisk {
                    newPosition.riskSeries = [
                        ATTimestampedValue(time: bar.time, value: newPosition.curRiskPct ?? 0)
                    ]
                }
            }

            if let profitTarget = strategy.profitTarget {
                let profitDistance = profitTarget(ATOpenPositionRuleArgs(
                    entryPrice: entryPrice,
                    position: newPosition,
                    bar: bar,
                    lookback: lookback,
                    parameters: strategyParameters
                ))
                newPosition.profitTarget = newPosition.direction == .long
                    ? entryPrice + profitDistance
                    : entryPrice - profitDistance
            }

            openPosition = newPosition
            positionStatus = .position
        case .position:
            guard var working = openPosition else { break }

            if let curStop = working.curStopPrice {
                if working.direction == .long {
                    if bar.low <= curStop {
                        closePosition(bar, curStop, "stop-loss")
                        break
                    }
                } else {
                    if bar.high >= curStop {
                        closePosition(bar, curStop, "stop-loss")
                        break
                    }
                }
            }

            if let trailingStopLoss = strategy.trailingStopLoss {
                let trailingStopDistance = trailingStopLoss(ATOpenPositionRuleArgs(
                    entryPrice: working.entryPrice,
                    position: working,
                    bar: bar,
                    lookback: lookback,
                    parameters: strategyParameters
                ))
                if working.direction == .long {
                    let newTrailingStopPrice = bar.close - trailingStopDistance
                    if let curStop = working.curStopPrice, newTrailingStopPrice > curStop {
                        working.curStopPrice = newTrailingStopPrice
                    }
                } else {
                    let newTrailingStopPrice = bar.close + trailingStopDistance
                    if let curStop = working.curStopPrice, newTrailingStopPrice < curStop {
                        working.curStopPrice = newTrailingStopPrice
                    }
                }
                if options.recordStopPrice {
                    if working.stopPriceSeries == nil { working.stopPriceSeries = [] }
                    working.stopPriceSeries?.append(ATTimestampedValue(time: bar.time, value: working.curStopPrice ?? 0))
                }
            }

            if let profitTarget = working.profitTarget {
                if working.direction == .long {
                    if bar.high >= profitTarget {
                        closePosition(bar, profitTarget, "profit-target")
                        break
                    }
                } else {
                    if bar.low <= profitTarget {
                        closePosition(bar, profitTarget, "profit-target")
                        break
                    }
                }
            }

            updatePosition(&working, bar)
            if let curRisk = working.curRiskPct, options.recordRisk {
                if working.riskSeries == nil { working.riskSeries = [] }
                working.riskSeries?.append(ATTimestampedValue(time: bar.time, value: curRisk))
            }

            if let exitRule = strategy.exitRule {
                exitRule(exitPosition, ATOpenPositionRuleArgs(
                    entryPrice: working.entryPrice,
                    position: working,
                    bar: bar,
                    lookback: lookback,
                    parameters: strategyParameters
                ))
            }

            openPosition = working
        case .exit:
            if openPosition != nil {
                closePosition(bar, bar.open, "exit-rule")
            }
        }
    }

    if let open = openPosition, let lastBar = indicatorsSeries.last {
        let lastTrade = finalizePosition(open, exitTime: lastBar.time, exitPrice: lastBar.close, exitReason: "finalize")
        completedTrades.append(lastTrade)
    }

    return (completedTrades, positionStatus)
}

public func analyze(startingCapital: Double, trades: [ATTrade]) -> ATAnalysis {
    if startingCapital <= 0 {
        return ATAnalysis()
    }

    var workingCapital = startingCapital
    var barCount = 0
    var peakCapital = startingCapital
    var workingDrawdown = 0.0
    var maxDrawdown = 0.0
    var maxDrawdownPct = 0.0
    var totalProfits = 0.0
    var totalLosses = 0.0
    var numWinningTrades = 0
    var numLosingTrades = 0
    var totalTrades = 0
    var maxRiskPct: Double?

    for trade in trades {
        totalTrades += 1
        maxRiskPct = max(maxRiskPct ?? 0, trade.riskPct)
        workingCapital *= trade.growth
        barCount += trade.holdingPeriod

        if workingCapital < peakCapital {
            workingDrawdown = workingCapital - peakCapital
        } else {
            peakCapital = workingCapital
            workingDrawdown = 0
        }

        if trade.profit > 0 {
            totalProfits += trade.profit
            numWinningTrades += 1
        } else {
            totalLosses += trade.profit
            numLosingTrades += 1
        }

        maxDrawdown = min(workingDrawdown, maxDrawdown)
        maxDrawdownPct = min((maxDrawdown / peakCapital) * 100, maxDrawdownPct)
    }

    let rmultiples = trades.map { $0.rmultiple }
    let expectency = rmultiples.count > 0 ? rmultiples.reduce(0, +) / Double(rmultiples.count) : 0
    let rmultipleStdDev: Double
    if rmultiples.count > 0 {
        let mean = expectency
        let sumSquares = rmultiples.map { (value: Double) -> Double in
            let diff = value - mean
            return diff * diff
        }.reduce(0, +)
        rmultipleStdDev = sqrt(sumSquares / Double(rmultiples.count))
    } else {
        rmultipleStdDev = 0
    }
    let systemQuality: Double? = rmultipleStdDev == 0 ? 0 : (expectency / rmultipleStdDev)

    let absTotalLosses = abs(totalLosses)
    let profitFactor: Double? = absTotalLosses > 0 ? totalProfits / absTotalLosses : 0
    let profit = workingCapital - startingCapital
    let profitPct = (profit / startingCapital) * 100
    let proportionWinning = totalTrades > 0 ? Double(numWinningTrades) / Double(totalTrades) : 0
    let proportionLosing = totalTrades > 0 ? Double(numLosingTrades) / Double(totalTrades) : 0
    let averageWinningTrade = numWinningTrades > 0 ? totalProfits / Double(numWinningTrades) : 0
    let averageLosingTrade = numLosingTrades > 0 ? totalLosses / Double(numLosingTrades) : 0

    return ATAnalysis(
        startingCapital: startingCapital,
        finalCapital: workingCapital,
        profit: profit,
        profitPct: profitPct,
        growth: workingCapital / startingCapital,
        totalTrades: totalTrades,
        barCount: barCount,
        maxDrawdown: maxDrawdown,
        maxDrawdownPct: maxDrawdownPct,
        maxRiskPct: maxRiskPct ?? 0,
        expectency: expectency,
        rmultipleStdDev: rmultipleStdDev,
        systemQuality: systemQuality ?? 0,
        profitFactor: profitFactor ?? 0,
        proportionProfitable: proportionWinning,
        percentProfitable: proportionWinning * 100,
        returnOnAccount: profitPct / abs(maxDrawdownPct),
        averageProfitPerTrade: totalTrades > 0 ? profit / Double(totalTrades) : 0,
        numWinningTrades: numWinningTrades,
        numLosingTrades: numLosingTrades,
        averageWinningTrade: averageWinningTrade,
        averageLosingTrade: averageLosingTrade,
        expectedValue: (proportionWinning * averageWinningTrade) + (proportionLosing * averageLosingTrade)
    )
}
