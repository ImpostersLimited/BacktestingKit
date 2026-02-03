import Foundation

public func v3setTechnicalIndicators(
    _ inputSeries: [ATBar],
    entryRules: [ATV3_SimulationRule],
    exitRules: [ATV3_SimulationRule]
) -> (series: [ATBar], maxDays: Int) {
    var dataFrame = DFDataFrame(indices: Array(0..<inputSeries.count), rows: inputSeries)
    var maxDays = 0
    var seriesCache: [String: DFSeries<Int, Double>] = [:]
    for rule in entryRules {
        let (updated, max) = v3bakeIndicators(dataFrame, rule: rule, seriesCache: &seriesCache)
        dataFrame = updated
        maxDays = max(maxDays, max)
    }
    for rule in exitRules {
        let (updated, max) = v3bakeIndicators(dataFrame, rule: rule, seriesCache: &seriesCache)
        dataFrame = updated
        maxDays = max(maxDays, max)
    }
    var series = dataFrame.rows
    if maxDays > 0, series.count > maxDays {
        series = Array(series.dropFirst(maxDays))
    }
    return (series, maxDays)
}

private func v3bakeIndicators(
    _ inputSeries: DFDataFrame<Int, ATBar>,
    rule: ATV3_SimulationRule,
    seriesCache: inout [String: DFSeries<Int, Double>]
) -> (DFDataFrame<Int, ATBar>, Int) {
    var series = inputSeries
    var maxDays = 0

    if let spec = extractIndicatorSpec(rule, isOne: true) {
        maxDays = max(maxDays, applyIndicatorDF(
            dataFrame: &series,
            spec: spec,
            seriesCache: &seriesCache
        ))
    }

    if let spec = extractIndicatorSpec(rule, isOne: false) {
        maxDays = max(maxDays, applyIndicatorDF(
            dataFrame: &series,
            spec: spec,
            seriesCache: &seriesCache
        ))
    }

    return (series, maxDays)
}

private struct IndicatorSpec {
    let type: TechnicalIndicators
    let name: String
    let figureOne: Double
    let figureTwo: Double
    let figureThree: Double
}

private func extractIndicatorSpec(_ rule: ATV3_SimulationRule, isOne: Bool) -> IndicatorSpec? {
    if isOne {
        guard let typeRaw = rule.indicatorOneType,
              let type = TechnicalIndicators(rawValue: typeRaw),
              let name = rule.indicatorOneName else { return nil }
        return IndicatorSpec(
            type: type,
            name: name,
            figureOne: rule.indicatorOneFigureOne ?? 0,
            figureTwo: rule.indicatorOneFigureTwo ?? 0,
            figureThree: rule.indicatorOneFigureThree ?? 0
        )
    } else {
        guard let typeRaw = rule.indicatorTwoType,
              let type = TechnicalIndicators(rawValue: typeRaw),
              let name = rule.indicatorTwoName else { return nil }
        return IndicatorSpec(
            type: type,
            name: name,
            figureOne: rule.indicatorTwoFigureOne ?? 0,
            figureTwo: rule.indicatorTwoFigureTwo ?? 0,
            figureThree: rule.indicatorTwoFigureThree ?? 0
        )
    }
}

private func applyIndicatorDF(
    dataFrame: inout DFDataFrame<Int, ATBar>,
    spec: IndicatorSpec,
    seriesCache: inout [String: DFSeries<Int, Double>]
) -> Int {
    let period1 = max(Int(spec.figureOne.rounded()), 0)
    let period2 = max(Int(spec.figureTwo.rounded()), 0)
    let period3 = max(Int(spec.figureThree.rounded()), 0)
    let cacheKey = "\(spec.type.rawValue)|\(spec.name)|\(period1)|\(period2)|\(period3)"
    if let cached = seriesCache[cacheKey] {
        dataFrame = dataFrame.withSeries(outputName(for: spec.type, baseName: spec.name), cached)
        return max(period1, period2 + period3)
    }
    switch spec.type {
    case .sma:
        let smaSeries = dataFrame.deflate { $0.close }.sma(period1)
        dataFrame = dataFrame.withSeries(spec.name, smaSeries)
        seriesCache[cacheKey] = smaSeries
        return period1
    case .ema:
        let emaSeries = dataFrame.deflate { $0.close }.ema(period1)
        dataFrame = dataFrame.withSeries(spec.name, emaSeries)
        seriesCache[cacheKey] = emaSeries
        return period1
    case .close, .constant:
        return 0
    case .bollingerUpper:
        let bb = dataFrame.deflate { $0.close }.bollinger(period1, spec.figureTwo, spec.figureThree)
        let upper = bb.deflate { $0.upper }
        dataFrame = dataFrame.withSeries(spec.name + "Upper", upper)
        seriesCache[cacheKey] = upper
        return period1
    case .bollingerLower:
        let bb = dataFrame.deflate { $0.close }.bollinger(period1, spec.figureTwo, spec.figureThree)
        let lower = bb.deflate { $0.lower }
        dataFrame = dataFrame.withSeries(spec.name + "Lower", lower)
        seriesCache[cacheKey] = lower
        return period1
    case .bollingerMiddle:
        let bb = dataFrame.deflate { $0.close }.bollinger(period1, spec.figureTwo, spec.figureThree)
        let middle = bb.deflate { $0.middle }
        dataFrame = dataFrame.withSeries(spec.name + "Middle", middle)
        seriesCache[cacheKey] = middle
        return period1
    case .macd:
        let macdFrame = dataFrame.deflate { $0.close }.macd(period1, period2, period3)
        let histogram = macdFrame.deflate { $0.histogram }
        dataFrame = dataFrame.withSeries(spec.name, histogram)
        seriesCache[cacheKey] = histogram
        return period2 + period3
    case .rsi:
        let rsiSeries = dataFrame.deflate { $0.close }.rsi(period1)
        dataFrame = dataFrame.withSeries(spec.name, rsiSeries)
        seriesCache[cacheKey] = rsiSeries
        return period1
    case .stochasticFastPercentD:
        let stoch = dataFrame.stochasticFast(period1, period2)
        let percentD = stoch.deflate { $0["percentD"] ?? 0 }
        dataFrame = dataFrame.withSeries(spec.name + "percentD", percentD)
        seriesCache[cacheKey] = percentD
        return period1 + period2
    case .stochasticFastPercentK:
        let stoch = dataFrame.stochasticFast(period1, period2)
        let percentK = stoch.deflate { $0["percentK"] ?? 0 }
        dataFrame = dataFrame.withSeries(spec.name + "percentK", percentK)
        seriesCache[cacheKey] = percentK
        return period1 + period2
    case .stochasticSlowPercentD:
        let stoch = dataFrame.stochasticSlow(period1, period2, period3)
        let percentD = stoch.deflate { $0["percentD"] ?? 0 }
        dataFrame = dataFrame.withSeries(spec.name + "percentD", percentD)
        seriesCache[cacheKey] = percentD
        return period1 + period2 + period3
    case .stochasticSlowPercentK:
        let stoch = dataFrame.stochasticSlow(period1, period2, period3)
        let percentK = stoch.deflate { $0["percentK"] ?? 0 }
        dataFrame = dataFrame.withSeries(spec.name + "percentK", percentK)
        seriesCache[cacheKey] = percentK
        return period1 + period2 + period3
    }
}

private func outputName(for type: TechnicalIndicators, baseName: String) -> String {
    switch type {
    case .bollingerUpper:
        return baseName + "Upper"
    case .bollingerMiddle:
        return baseName + "Middle"
    case .bollingerLower:
        return baseName + "Lower"
    case .stochasticFastPercentD, .stochasticSlowPercentD:
        return baseName + "percentD"
    case .stochasticFastPercentK, .stochasticSlowPercentK:
        return baseName + "percentK"
    default:
        return baseName
    }
}
func applyIndicator(
    series: inout [ATBar],
    type: TechnicalIndicators,
    name: String,
    figureOne: Double,
    figureTwo: Double,
    figureThree: Double
) -> Int {
    let count = series.count
    if count == 0 { return 0 }
    let period1 = max(Int(figureOne.rounded()), 0)
    let period2 = max(Int(figureTwo.rounded()), 0)
    let period3 = max(Int(figureThree.rounded()), 0)

    switch type {
    case .sma:
        let values = series.map { $0.close }
        let smaValues = sma(values, period: period1)
        assignSeries(&series, name: name, values: smaValues)
        return period1
    case .ema:
        let values = series.map { $0.close }
        let emaValues = ema(values, period: period1)
        assignSeries(&series, name: name, values: emaValues)
        return period1
    case .close, .constant:
        return 0
    case .bollingerUpper:
        let bands = bollingerBands(series.map { $0.close }, period: period1, stdDevMultUpper: figureTwo, stdDevMultLower: figureThree)
        assignSeries(&series, name: name + "Upper", values: bands.upper)
        return period1
    case .bollingerLower:
        let bands = bollingerBands(series.map { $0.close }, period: period1, stdDevMultUpper: figureTwo, stdDevMultLower: figureThree)
        assignSeries(&series, name: name + "Lower", values: bands.lower)
        return period1
    case .bollingerMiddle:
        let bands = bollingerBands(series.map { $0.close }, period: period1, stdDevMultUpper: figureTwo, stdDevMultLower: figureThree)
        assignSeries(&series, name: name + "Middle", values: bands.middle)
        return period1
    case .macd:
        let macdValues = macd(series.map { $0.close }, fast: period1, slow: period2, signal: period3)
        assignSeries(&series, name: name, values: macdValues.histogram)
        return period2 + period3
    case .rsi:
        let rsiValues = rsi(series.map { $0.close }, period: period1)
        assignSeries(&series, name: name, values: rsiValues)
        return period1
    case .stochasticFastPercentD:
        let stoch = stochasticFast(series: series, periodK: period1, periodD: period2)
        assignSeries(&series, name: name + "percentD", values: stoch.percentD)
        return period1 + period2
    case .stochasticFastPercentK:
        let stoch = stochasticFast(series: series, periodK: period1, periodD: period2)
        assignSeries(&series, name: name + "percentK", values: stoch.percentK)
        return period1 + period2
    case .stochasticSlowPercentD:
        let stoch = stochasticSlow(series: series, periodK: period1, periodD: period2, periodSlow: period3)
        assignSeries(&series, name: name + "percentD", values: stoch.percentD)
        return period1 + period2 + period3
    case .stochasticSlowPercentK:
        let stoch = stochasticSlow(series: series, periodK: period1, periodD: period2, periodSlow: period3)
        assignSeries(&series, name: name + "percentK", values: stoch.percentK)
        return period1 + period2 + period3
    }
}

private func assignSeries(_ series: inout [ATBar], name: String, values: [Double?]) {
    guard series.count == values.count else { return }
    for i in 0..<series.count {
        if let value = values[i] {
            series[i].indicators[name] = value
        }
    }
}

private func sma(_ values: [Double], period: Int) -> [Double?] {
    guard period > 0, values.count >= period else {
        return Array(repeating: nil, count: values.count)
    }
    var result = Array(repeating: nil as Double?, count: values.count)
    var sum = 0.0
    for i in 0..<values.count {
        sum += values[i]
        if i >= period { sum -= values[i - period] }
        if i >= period - 1 {
            result[i] = sum / Double(period)
        }
    }
    return result
}

private func ema(_ values: [Double], period: Int) -> [Double?] {
    guard period > 0, values.count >= period else {
        return Array(repeating: nil, count: values.count)
    }
    var result = Array(repeating: nil as Double?, count: values.count)
    let k = 2.0 / Double(period + 1)
    for i in (period - 1)..<values.count {
        let window = Array(values[(i - period + 1)...i])
        result[i] = computeEma(window, multiplier: k)
    }
    return result
}

private func computeEma(_ values: [Double], multiplier: Double) -> Double {
    if values.isEmpty { return 0 }
    if values.count == 1 { return values[0] }
    var latest = values[0]
    for i in 1..<values.count {
        latest = (multiplier * values[i]) + ((1 - multiplier) * latest)
    }
    return latest
}

private func rsi(_ values: [Double], period: Int) -> [Double?] {
    guard period > 0, values.count >= period + 1 else {
        return Array(repeating: nil, count: values.count)
    }
    var result = Array(repeating: nil as Double?, count: values.count)
    for i in period..<values.count {
        let window = Array(values[(i - period)...i])
        let changes = zip(window.dropFirst(), window.dropLast()).map { $0 - $1 }
        let averageLoss = abs(changes.map { $0 < 0 ? $0 : 0 }.reduce(0, +) / Double(period))
        if averageLoss < Double.ulpOfOne {
            result[i] = 100
        } else {
            let averageGain = changes.map { $0 > 0 ? $0 : 0 }.reduce(0, +) / Double(period)
            let relativeStrength = averageGain / averageLoss
            result[i] = 100 - (100 / (1 + relativeStrength))
        }
    }
    return result
}

private func bollingerBands(_ values: [Double], period: Int, stdDevMultUpper: Double, stdDevMultLower: Double) -> (upper: [Double?], middle: [Double?], lower: [Double?]) {
    guard period > 0, values.count >= period else {
        let empty = Array(repeating: nil as Double?, count: values.count)
        return (empty, empty, empty)
    }
    var upper = Array(repeating: nil as Double?, count: values.count)
    var middle = Array(repeating: nil as Double?, count: values.count)
    var lower = Array(repeating: nil as Double?, count: values.count)
    var sum = 0.0
    var sumSq = 0.0
    for i in 0..<values.count {
        let v = values[i]
        sum += v
        sumSq += v * v
        if i >= period {
            let old = values[i - period]
            sum -= old
            sumSq -= old * old
        }
        if i >= period - 1 {
            let mean = sum / Double(period)
            let variance = max((sumSq / Double(period)) - (mean * mean), 0)
            let stddev = sqrt(variance)
            middle[i] = mean
            upper[i] = mean + stdDevMultUpper * stddev
            lower[i] = mean - stdDevMultLower * stddev
        }
    }
    return (upper, middle, lower)
}

private func macd(_ values: [Double], fast: Int, slow: Int, signal: Int) -> (macd: [Double?], signal: [Double?], histogram: [Double?]) {
    let fastEma = ema(values, period: fast)
    let slowEma = ema(values, period: slow)
    var macdLine = Array(repeating: nil as Double?, count: values.count)
    let startIndex = max(slow - 1, 0)
    if startIndex < values.count {
        for i in startIndex..<values.count {
            if let f = fastEma[i], let s = slowEma[i] {
                macdLine[i] = f - s
            }
        }
    }
    var signalLine = Array(repeating: nil as Double?, count: values.count)
    if signal > 0, startIndex < values.count {
        let macdValues = macdLine[startIndex...].compactMap { $0 }
        if macdValues.count >= signal {
            let k = 2.0 / Double(signal + 1)
            for offset in (signal - 1)..<macdValues.count {
                let window = Array(macdValues[(offset - signal + 1)...offset])
                let emaValue = computeEma(window, multiplier: k)
                let idx = startIndex + offset
                if idx < signalLine.count {
                    signalLine[idx] = emaValue
                }
            }
        }
    }
    var histogram = Array(repeating: nil as Double?, count: values.count)
    for i in 0..<values.count {
        if let m = macdLine[i], let s = signalLine[i] {
            histogram[i] = m - s
        }
    }
    return (macdLine, signalLine, histogram)
}

private func stochasticFast(series: [ATBar], periodK: Int, periodD: Int) -> (percentK: [Double?], percentD: [Double?]) {
    let count = series.count
    var percentK = Array(repeating: nil as Double?, count: count)
    guard periodK > 0, count >= periodK else {
        return (percentK, Array(repeating: nil, count: count))
    }
    for i in (periodK - 1)..<count {
        let window = series[(i - periodK + 1)...i]
        let lowestLow = window.map { $0.low }.min() ?? series[i].low
        let highestHigh = window.map { $0.high }.max() ?? series[i].high
        let denom = highestHigh - lowestLow
        let value = denom == 0 ? 0 : ((series[i].close - lowestLow) / denom) * 100
        percentK[i] = value
    }
    let percentD = smaOptional(percentK, period: periodD)
    return (percentK, percentD)
}

private func stochasticSlow(series: [ATBar], periodK: Int, periodD: Int, periodSlow: Int) -> (percentK: [Double?], percentD: [Double?]) {
    let fastK = stochasticFast(series: series, periodK: periodK, periodD: periodD).percentK
    let fastD = smaOptional(fastK, period: periodD)
    let slowK = smaOptional(fastK, period: periodSlow)
    let slowD = smaOptional(fastD, period: periodSlow)
    return (slowK, slowD)
}

private func smaOptional(_ values: [Double?], period: Int) -> [Double?] {
    guard period > 0 else { return values }
    var result = Array(repeating: nil as Double?, count: values.count)
    var window: [Double] = []
    window.reserveCapacity(period)
    for i in 0..<values.count {
        if let v = values[i] {
            window.append(v)
        } else {
            window.append(Double.nan)
        }
        if window.count > period {
            window.removeFirst()
        }
        if window.count == period && !window.contains(where: { $0.isNaN }) {
            let sum = window.reduce(0, +)
            result[i] = sum / Double(period)
        }
    }
    return result
}
