import Foundation

public func v2getCheckingFunction(
    config: ATV2.SimulationPolicyConfig
) -> (ATCheckFn, ATCheckFn) {
    let entryCheck: ATCheckFn = { args in
        return evaluateV2Rules(config.entryRules, args: args)
    }
    let exitCheck: ATCheckFn = { args in
        return evaluateV2Rules(config.exitRules, args: args)
    }
    return (entryCheck, exitCheck)
}

private func evaluateV2Rules(_ rules: [ATV2.SimulationRule], args: ATRuleParams) -> Bool {
    var result = true
    for item in rules {
        guard let typeOne = TechnicalIndicators(rawValue: item.indicatorOneType.rawValue),
              let typeTwo = TechnicalIndicators(rawValue: item.indicatorTwoType.rawValue),
              let compare = CompareOption(rawValue: item.compare.rawValue) else {
            result = false
            continue
        }

        let valueOne = resolveValue(
            type: typeOne,
            name: item.indicatorOneName,
            figureOne: Double(item.indicatorOneFigure[safe: 0] ?? 0),
            bar: args.bar
        )
        let valueTwo = resolveValue(
            type: typeTwo,
            name: item.indicatorTwoName,
            figureOne: Double(item.indicatorTwoFigure[safe: 0] ?? 0),
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
