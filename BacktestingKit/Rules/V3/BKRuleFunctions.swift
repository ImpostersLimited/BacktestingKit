import Foundation

/// Provides the `BKCheckFn` typealias for BacktestingKit interoperability.
public typealias BKCheckFn = (_ args: BKRuleParams) -> Bool

/// Executes `v3getCheckingFunction`.
public func v3getCheckingFunction(
    entryRules: [BKV3_SimulationRule],
    exitRules: [BKV3_SimulationRule]
) -> (BKCheckFn, BKCheckFn) {
    let entryCheck: BKCheckFn = { args in
        return evaluateRules(entryRules, args: args)
    }
    let exitCheck: BKCheckFn = { args in
        return evaluateRules(exitRules, args: args)
    }
    return (entryCheck, exitCheck)
}

private func evaluateRules(_ rules: [BKV3_SimulationRule], args: BKRuleParams) -> Bool {
    var result = true
    for item in rules {
        guard let typeOneRaw = item.indicatorOneType,
              let typeOne = TechnicalIndicators(rawValue: typeOneRaw),
              let nameOne = item.indicatorOneName,
              let typeTwoRaw = item.indicatorTwoType,
              let typeTwo = TechnicalIndicators(rawValue: typeTwoRaw),
              let nameTwo = item.indicatorTwoName,
              let compareRaw = item.compare,
              let compare = CompareOption(rawValue: compareRaw) else {
            result = false
            continue
        }

        let valueOne = resolveValue(
            type: typeOne,
            name: nameOne,
            figureOne: item.indicatorOneFigureOne ?? 0,
            bar: args.bar
        )
        let valueTwo = resolveValue(
            type: typeTwo,
            name: nameTwo,
            figureOne: item.indicatorTwoFigureOne ?? 0,
            bar: args.bar
        )

        let temp: Bool
        if let v1 = valueOne, let v2 = valueTwo {
            switch compare {
            case .equalTo:
                temp = v1 == v2
            case .largerOrEqualTo:
                temp = v1 >= v2
            case .largerThan:
                temp = v1 > v2
            case .smallThan:
                temp = v1 < v2
            case .smallerOrEqualTo:
                temp = v1 <= v2
            }
        } else {
            temp = false
        }
        if result && !temp {
            result = false
        }
    }
    return result
}

func resolveValue(type: TechnicalIndicators, name: String, figureOne: Double, bar: BKBar) -> Double? {
    switch type {
    case .constant:
        return figureOne
    case .close:
        return bar.value(forName: "close")
    case .stochasticFastPercentD:
        return bar.value(forName: name + "percentD")
    case .stochasticFastPercentK:
        return bar.value(forName: name + "percentK")
    case .stochasticSlowPercentD:
        return bar.value(forName: name + "percentD")
    case .stochasticSlowPercentK:
        return bar.value(forName: name + "percentK")
    case .bollingerUpper:
        return bar.value(forName: name + "Upper")
    case .bollingerMiddle:
        return bar.value(forName: name + "Middle")
    case .bollingerLower:
        return bar.value(forName: name + "Lower")
    default:
        return bar.value(forName: name)
    }
}
