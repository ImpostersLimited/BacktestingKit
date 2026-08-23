import Foundation

/// Executes `getStrategy`.
public func getStrategy(
    policy: SimulationPolicy = .sma,
    riskPct: Double = 15,
    entryFn: @escaping BKCheckFn,
    exitFn: @escaping BKCheckFn,
    trailingStopLoss: Bool = false,
    profitFactor: Double = Double.greatestFiniteMagnitude
) -> BKStrategy {
    let usesCrossingSignals = policy == .smaCrossover || policy == .emaCrossover
    let signal: (BKCheckFn, BKRuleParams) -> Bool = { check, args in
        guard usesCrossingSignals else { return check(args) }
        guard args.lookback.count >= 2 else { return false }
        let previous = BKRuleParams(
            bar: args.lookback[args.lookback.count - 2],
            lookback: Array(args.lookback.dropLast()),
            parameters: args.parameters
        )
        return !check(previous) && check(args)
    }

    if trailingStopLoss {
        return BKStrategy(
            lookbackPeriod: usesCrossingSignals ? 2 : 1,
            entryRule: { enterPosition, args in
                if signal(entryFn, args) {
                    enterPosition(BKEnterPositionOptions(direction: .long, entryPrice: nil))
                }
            },
            exitRule: { exitPosition, args in
                let ruleArgs = BKRuleParams(bar: args.bar, lookback: args.lookback, parameters: args.parameters)
                if signal(exitFn, ruleArgs) {
                    exitPosition()
                }
            },
            stopLoss: { args in
                return args.entryPrice * (riskPct / 100)
            },
            trailingStopLoss: { args in
                let highest = args.lookback.map { $0.high }.max() ?? args.bar.high
                return highest * (riskPct / 100)
            },
            profitTarget: { args in
                return args.entryPrice * profitFactor
            }
        )
    }

    return BKStrategy(
        lookbackPeriod: usesCrossingSignals ? 2 : 1,
        entryRule: { enterPosition, args in
            if signal(entryFn, args) {
                enterPosition(BKEnterPositionOptions(direction: .long, entryPrice: nil))
            }
        },
        exitRule: { exitPosition, args in
            let ruleArgs = BKRuleParams(bar: args.bar, lookback: args.lookback, parameters: args.parameters)
            if signal(exitFn, ruleArgs) {
                exitPosition()
            }
        },
        stopLoss: { args in
            return args.entryPrice * (riskPct / 100)
        },
        profitTarget: { args in
            return args.entryPrice * profitFactor
        }
    )
}
