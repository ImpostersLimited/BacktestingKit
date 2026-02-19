import Foundation

/// Executes `bollingerPreset`.
public func bollingerPreset(trailing: Bool = true, stopLoss: Double = 15) -> SimulationPolicyConfig {
    let ruleOne = SimulationRule(
        indicatorOneName: "ruleOneEntry",
        indicatorOneType: .bollingerLower,
        indicatorOneFigure: [20, 2, 2],
        compare: .smallThan,
        indicatorTwoName: "ruleOneExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    let ruleTwo = SimulationRule(
        indicatorOneName: "ruleTwoEntry",
        indicatorOneType: .bollingerUpper,
        indicatorOneFigure: [20, 2, 2],
        compare: .smallThan,
        indicatorTwoName: "ruleTwoExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    return SimulationPolicyConfig(
        policy: .bollinger,
        trailingStopLoss: trailing,
        stopLossFigure: stopLoss,
        profitFactor: pow(2.0, 32.0),
        entryRules: [ruleOne],
        exitRules: [ruleTwo],
        t1: 5,
        t2: 6
    )
}

/// Executes `customPreset`.
public func customPreset(trailing: Bool = true, stopLoss: Double = 15) -> SimulationPolicyConfig {
    let ruleOne = SimulationRule(
        indicatorOneName: "ruleOneEntry",
        indicatorOneType: .sma,
        indicatorOneFigure: [15, 0, 0],
        compare: .smallerOrEqualTo,
        indicatorTwoName: "ruleOneExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    let ruleTwo = SimulationRule(
        indicatorOneName: "ruleTwoEntry",
        indicatorOneType: .sma,
        indicatorOneFigure: [15, 0, 0],
        compare: .largerThan,
        indicatorTwoName: "ruleTwoExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    return SimulationPolicyConfig(
        policy: .sma,
        trailingStopLoss: trailing,
        stopLossFigure: stopLoss,
        profitFactor: pow(2.0, 32.0),
        entryRules: [ruleOne],
        exitRules: [ruleTwo],
        t1: 5,
        t2: 6
    )
}

/// Executes `emaPreset`.
public func emaPreset(trailing: Bool = true, stopLoss: Double = 15) -> SimulationPolicyConfig {
    let ruleOne = SimulationRule(
        indicatorOneName: "ruleOneEntry",
        indicatorOneType: .ema,
        indicatorOneFigure: [15, 0, 0],
        compare: .smallerOrEqualTo,
        indicatorTwoName: "ruleOneExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    let ruleTwo = SimulationRule(
        indicatorOneName: "ruleTwoEntry",
        indicatorOneType: .ema,
        indicatorOneFigure: [15, 0, 0],
        compare: .largerThan,
        indicatorTwoName: "ruleTwoExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    return SimulationPolicyConfig(
        policy: .ema,
        trailingStopLoss: trailing,
        stopLossFigure: stopLoss,
        profitFactor: pow(2.0, 32.0),
        entryRules: [ruleOne],
        exitRules: [ruleTwo],
        t1: 5,
        t2: 6
    )
}

/// Executes `smaPreset`.
public func smaPreset(trailing: Bool = true, stopLoss: Double = 15) -> SimulationPolicyConfig {
    let ruleOne = SimulationRule(
        indicatorOneName: "ruleOneEntry",
        indicatorOneType: .sma,
        indicatorOneFigure: [15, 0, 0],
        compare: .smallerOrEqualTo,
        indicatorTwoName: "ruleOneExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    let ruleTwo = SimulationRule(
        indicatorOneName: "ruleTwoEntry",
        indicatorOneType: .sma,
        indicatorOneFigure: [15, 0, 0],
        compare: .largerThan,
        indicatorTwoName: "ruleTwoExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    return SimulationPolicyConfig(
        policy: .sma,
        trailingStopLoss: trailing,
        stopLossFigure: stopLoss,
        profitFactor: pow(2.0, 32.0),
        entryRules: [ruleOne],
        exitRules: [ruleTwo],
        t1: 5,
        t2: 6
    )
}

/// Executes `macdPreset`.
public func macdPreset(trailing: Bool = true, stopLoss: Double = 15) -> SimulationPolicyConfig {
    let ruleOne = SimulationRule(
        indicatorOneName: "ruleOneEntry",
        indicatorOneType: .macd,
        indicatorOneFigure: [12, 26, 9],
        compare: .largerOrEqualTo,
        indicatorTwoName: "ruleOneExit",
        indicatorTwoType: .constant,
        indicatorTwoFigure: [0, 0, 0]
    )
    let ruleTwo = SimulationRule(
        indicatorOneName: "ruleTwoEntry",
        indicatorOneType: .macd,
        indicatorOneFigure: [12, 26, 9],
        compare: .smallThan,
        indicatorTwoName: "ruleTwoExit",
        indicatorTwoType: .constant,
        indicatorTwoFigure: [0, 0, 0]
    )
    return SimulationPolicyConfig(
        policy: .macd,
        trailingStopLoss: trailing,
        stopLossFigure: stopLoss,
        profitFactor: pow(2.0, 32.0),
        entryRules: [ruleOne],
        exitRules: [ruleTwo],
        t1: 5,
        t2: 6
    )
}

/// Executes `macdSmaPreset`.
public func macdSmaPreset(trailing: Bool = true, stopLoss: Double = 15) -> SimulationPolicyConfig {
    let ruleOne = SimulationRule(
        indicatorOneName: "ruleOneEntry",
        indicatorOneType: .macd,
        indicatorOneFigure: [12, 26, 9],
        compare: .largerOrEqualTo,
        indicatorTwoName: "ruleOneExit",
        indicatorTwoType: .constant,
        indicatorTwoFigure: [0, 0, 0]
    )
    let ruleThree = SimulationRule(
        indicatorOneName: "ruleThreeEntry",
        indicatorOneType: .sma,
        indicatorOneFigure: [15, 0, 0],
        compare: .smallerOrEqualTo,
        indicatorTwoName: "ruleThreeExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    let ruleTwo = SimulationRule(
        indicatorOneName: "ruleTwoEntry",
        indicatorOneType: .macd,
        indicatorOneFigure: [12, 26, 9],
        compare: .smallThan,
        indicatorTwoName: "ruleTwoExit",
        indicatorTwoType: .constant,
        indicatorTwoFigure: [0, 0, 0]
    )
    let ruleFour = SimulationRule(
        indicatorOneName: "ruleFourEntry",
        indicatorOneType: .sma,
        indicatorOneFigure: [15, 0, 0],
        compare: .largerThan,
        indicatorTwoName: "ruleFourExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    return SimulationPolicyConfig(
        policy: .macdSma,
        trailingStopLoss: trailing,
        stopLossFigure: stopLoss,
        profitFactor: pow(2.0, 32.0),
        entryRules: [ruleOne, ruleThree],
        exitRules: [ruleTwo, ruleFour],
        t1: 5,
        t2: 6
    )
}

/// Executes `macdEmaPreset`.
public func macdEmaPreset(trailing: Bool = true, stopLoss: Double = 15) -> SimulationPolicyConfig {
    let ruleOne = SimulationRule(
        indicatorOneName: "ruleOneEntry",
        indicatorOneType: .macd,
        indicatorOneFigure: [12, 26, 9],
        compare: .largerOrEqualTo,
        indicatorTwoName: "ruleOneExit",
        indicatorTwoType: .constant,
        indicatorTwoFigure: [0, 0, 0]
    )
    let ruleThree = SimulationRule(
        indicatorOneName: "ruleThreeEntry",
        indicatorOneType: .ema,
        indicatorOneFigure: [15, 0, 0],
        compare: .smallerOrEqualTo,
        indicatorTwoName: "ruleThreeExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    let ruleTwo = SimulationRule(
        indicatorOneName: "ruleTwoEntry",
        indicatorOneType: .macd,
        indicatorOneFigure: [12, 26, 9],
        compare: .smallThan,
        indicatorTwoName: "ruleTwoExit",
        indicatorTwoType: .constant,
        indicatorTwoFigure: [0, 0, 0]
    )
    let ruleFour = SimulationRule(
        indicatorOneName: "ruleFourEntry",
        indicatorOneType: .ema,
        indicatorOneFigure: [15, 0, 0],
        compare: .largerThan,
        indicatorTwoName: "ruleFourExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    return SimulationPolicyConfig(
        policy: .macdEma,
        trailingStopLoss: trailing,
        stopLossFigure: stopLoss,
        profitFactor: pow(2.0, 32.0),
        entryRules: [ruleOne, ruleThree],
        exitRules: [ruleTwo, ruleFour],
        t1: 5,
        t2: 6
    )
}

/// Executes `smaCrossoverPreset`.
public func smaCrossoverPreset(trailing: Bool = true, stopLoss: Double = 15) -> SimulationPolicyConfig {
    let ruleOne = SimulationRule(
        indicatorOneName: "ruleOneEntry",
        indicatorOneType: .sma,
        indicatorOneFigure: [50, 0, 0],
        compare: .smallThan,
        indicatorTwoName: "ruleOneExit",
        indicatorTwoType: .sma,
        indicatorTwoFigure: [200, 0, 0]
    )
    let ruleTwo = SimulationRule(
        indicatorOneName: "ruleTwoEntry",
        indicatorOneType: .sma,
        indicatorOneFigure: [50, 0, 0],
        compare: .largerOrEqualTo,
        indicatorTwoName: "ruleTwoExit",
        indicatorTwoType: .sma,
        indicatorTwoFigure: [200, 0, 0]
    )
    return SimulationPolicyConfig(
        policy: .smaCrossover,
        trailingStopLoss: trailing,
        stopLossFigure: stopLoss,
        profitFactor: pow(2.0, 32.0),
        entryRules: [ruleOne],
        exitRules: [ruleTwo],
        t1: 5,
        t2: 6
    )
}

/// Executes `emaCrossoverPreset`.
public func emaCrossoverPreset(trailing: Bool = true, stopLoss: Double = 15) -> SimulationPolicyConfig {
    let ruleOne = SimulationRule(
        indicatorOneName: "ruleOneEntry",
        indicatorOneType: .ema,
        indicatorOneFigure: [50, 0, 0],
        compare: .smallThan,
        indicatorTwoName: "ruleOneExit",
        indicatorTwoType: .ema,
        indicatorTwoFigure: [200, 0, 0]
    )
    let ruleTwo = SimulationRule(
        indicatorOneName: "ruleTwoEntry",
        indicatorOneType: .ema,
        indicatorOneFigure: [50, 0, 0],
        compare: .largerOrEqualTo,
        indicatorTwoName: "ruleTwoExit",
        indicatorTwoType: .ema,
        indicatorTwoFigure: [200, 0, 0]
    )
    return SimulationPolicyConfig(
        policy: .emaCrossover,
        trailingStopLoss: trailing,
        stopLossFigure: stopLoss,
        profitFactor: pow(2.0, 32.0),
        entryRules: [ruleOne],
        exitRules: [ruleTwo],
        t1: 5,
        t2: 6
    )
}

/// Executes `smaMeanReversion`.
public func smaMeanReversion(trailing: Bool = true, stopLoss: Double = 15) -> SimulationPolicyConfig {
    let ruleOne = SimulationRule(
        indicatorOneName: "ruleOneEntry",
        indicatorOneType: .sma,
        indicatorOneFigure: [15, 0, 0],
        compare: .largerOrEqualTo,
        indicatorTwoName: "ruleOneExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    let ruleTwo = SimulationRule(
        indicatorOneName: "ruleTwoEntry",
        indicatorOneType: .sma,
        indicatorOneFigure: [15, 0, 0],
        compare: .smallThan,
        indicatorTwoName: "ruleTwoExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    return SimulationPolicyConfig(
        policy: .smaMeanReversion,
        trailingStopLoss: trailing,
        stopLossFigure: stopLoss,
        profitFactor: pow(2.0, 32.0),
        entryRules: [ruleOne],
        exitRules: [ruleTwo],
        t1: 5,
        t2: 6
    )
}

/// Executes `emaMeanReversion`.
public func emaMeanReversion(trailing: Bool = true, stopLoss: Double = 15) -> SimulationPolicyConfig {
    let ruleOne = SimulationRule(
        indicatorOneName: "ruleOneEntry",
        indicatorOneType: .ema,
        indicatorOneFigure: [15, 0, 0],
        compare: .largerOrEqualTo,
        indicatorTwoName: "ruleOneExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    let ruleTwo = SimulationRule(
        indicatorOneName: "ruleTwoEntry",
        indicatorOneType: .ema,
        indicatorOneFigure: [15, 0, 0],
        compare: .smallThan,
        indicatorTwoName: "ruleTwoExit",
        indicatorTwoType: .close,
        indicatorTwoFigure: [0, 0, 0]
    )
    return SimulationPolicyConfig(
        policy: .emaMeanReversion,
        trailingStopLoss: trailing,
        stopLossFigure: stopLoss,
        profitFactor: pow(2.0, 32.0),
        entryRules: [ruleOne],
        exitRules: [ruleTwo],
        t1: 5,
        t2: 6
    )
}

/// Executes `stochasticFastPreset`.
public func stochasticFastPreset(trailing: Bool = true, stopLoss: Double = 15) -> SimulationPolicyConfig {
    let ruleOne = SimulationRule(
        indicatorOneName: "ruleOneEntry",
        indicatorOneType: .stochasticFastPercentK,
        indicatorOneFigure: [14, 3, 0],
        compare: .largerOrEqualTo,
        indicatorTwoName: "ruleOneExit",
        indicatorTwoType: .stochasticFastPercentK,
        indicatorTwoFigure: [14, 3, 0]
    )
    let ruleTwo = SimulationRule(
        indicatorOneName: "ruleTwoEntry",
        indicatorOneType: .stochasticFastPercentK,
        indicatorOneFigure: [14, 3, 0],
        compare: .smallThan,
        indicatorTwoName: "ruleTwoExit",
        indicatorTwoType: .stochasticFastPercentK,
        indicatorTwoFigure: [14, 3, 0]
    )
    return SimulationPolicyConfig(
        policy: .stochasticFast,
        trailingStopLoss: trailing,
        stopLossFigure: stopLoss,
        profitFactor: pow(2.0, 32.0),
        entryRules: [ruleOne],
        exitRules: [ruleTwo],
        t1: 5,
        t2: 6
    )
}

/// Executes `stochasticSlowPreset`.
public func stochasticSlowPreset(trailing: Bool = true, stopLoss: Double = 15) -> SimulationPolicyConfig {
    let ruleOne = SimulationRule(
        indicatorOneName: "ruleOneEntry",
        indicatorOneType: .stochasticSlowPercentK,
        indicatorOneFigure: [14, 3, 3],
        compare: .largerOrEqualTo,
        indicatorTwoName: "ruleOneExit",
        indicatorTwoType: .stochasticSlowPercentD,
        indicatorTwoFigure: [14, 3, 3]
    )
    let ruleTwo = SimulationRule(
        indicatorOneName: "ruleTwoEntry",
        indicatorOneType: .stochasticSlowPercentK,
        indicatorOneFigure: [14, 3, 3],
        compare: .smallThan,
        indicatorTwoName: "ruleTwoExit",
        indicatorTwoType: .stochasticSlowPercentD,
        indicatorTwoFigure: [14, 3, 3]
    )
    return SimulationPolicyConfig(
        policy: .stochasticSlow,
        trailingStopLoss: trailing,
        stopLossFigure: stopLoss,
        profitFactor: pow(2.0, 32.0),
        entryRules: [ruleOne],
        exitRules: [ruleTwo],
        t1: 5,
        t2: 6
    )
}

/// Executes `v3GetPresetRules`.
public func v3GetPresetRules(preset: SimulationPolicy) -> ([SimulationRule], [SimulationRule]) {
    let config = getSimulatePolicyConfig(preset: preset)
    return (config.entryRules, config.exitRules)
}

/// Executes `getSimulatePolicyConfig`.
public func getSimulatePolicyConfig(preset: SimulationPolicy) -> SimulationPolicyConfig {
    switch preset {
    case .bollinger:
        return bollingerPreset()
    case .customStrategy:
        return customPreset()
    case .ema:
        return emaPreset()
    case .sma:
        return smaPreset()
    case .macd:
        return macdPreset()
    case .smaCrossover:
        return smaCrossoverPreset()
    case .smaMeanReversion:
        return smaMeanReversion()
    case .macdSma:
        return macdSmaPreset()
    case .stochasticFast:
        return stochasticFastPreset()
    case .stochasticSlow:
        return stochasticSlowPreset()
    case .emaMeanReversion:
        return emaMeanReversion()
    case .emaCrossover:
        return emaCrossoverPreset()
    case .macdEma:
        return macdEmaPreset()
    }
}

