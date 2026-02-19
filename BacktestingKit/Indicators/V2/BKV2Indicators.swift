import Foundation

/// Executes `v2setTechnicalIndicators`.
public func v2setTechnicalIndicators(
    _ inputSeries: [BKBar],
    entryRules: [BKV2.SimulationRule],
    exitRules: [BKV2.SimulationRule]
) -> (series: [BKBar], maxDays: Int) {
    var series = inputSeries
    var maxDays = 0
    for rule in entryRules {
        let (updated, ruleMaxDays) = v2bakeIndicators(series, rule: rule)
        series = updated
        maxDays = Swift.max(maxDays, ruleMaxDays)
    }
    for rule in exitRules {
        let (updated, ruleMaxDays) = v2bakeIndicators(series, rule: rule)
        series = updated
        maxDays = Swift.max(maxDays, ruleMaxDays)
    }
    if maxDays > 0, series.count > maxDays {
        series = Array(series.dropFirst(maxDays))
    }
    return (series, maxDays)
}

private func v2bakeIndicators(_ inputSeries: [BKBar], rule: BKV2.SimulationRule) -> ([BKBar], Int) {
    var series = inputSeries
    var maxDays = 0

    if let type = TechnicalIndicators(rawValue: rule.indicatorOneType.rawValue) {
        maxDays = max(maxDays, applyIndicator(
            series: &series,
            type: type,
            name: rule.indicatorOneName,
            figureOne: Double(rule.indicatorOneFigure[safe: 0] ?? 0),
            figureTwo: Double(rule.indicatorOneFigure[safe: 1] ?? 0),
            figureThree: Double(rule.indicatorOneFigure[safe: 2] ?? 0)
        ))
    }

    if let type = TechnicalIndicators(rawValue: rule.indicatorTwoType.rawValue) {
        maxDays = max(maxDays, applyIndicator(
            series: &series,
            type: type,
            name: rule.indicatorTwoName,
            figureOne: Double(rule.indicatorTwoFigure[safe: 0] ?? 0),
            figureTwo: Double(rule.indicatorTwoFigure[safe: 1] ?? 0),
            figureThree: Double(rule.indicatorTwoFigure[safe: 2] ?? 0)
        ))
    }

    return (series, maxDays)
}
