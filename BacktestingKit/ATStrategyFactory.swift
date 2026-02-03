import Foundation

public func getStrategy(
    policy: SimulationPolicy = .sma,
    riskPct: Double = 15,
    entryFn: @escaping ATCheckFn,
    exitFn: @escaping ATCheckFn,
    trailingStopLoss: Bool = false,
    profitFactor: Double = Double.greatestFiniteMagnitude
) -> ATStrategy {
    if trailingStopLoss {
        return ATStrategy(
            entryRule: { enterPosition, args in
                if entryFn(args) {
                    enterPosition(ATEnterPositionOptions(direction: .long, entryPrice: nil))
                }
            },
            exitRule: { exitPosition, args in
                if exitFn(ATRuleParams(bar: args.bar, lookback: args.lookback, parameters: args.parameters)) {
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

    return ATStrategy(
        entryRule: { enterPosition, args in
            if entryFn(args) {
                enterPosition(ATEnterPositionOptions(direction: .long, entryPrice: nil))
            }
        },
        exitRule: { exitPosition, args in
            if exitFn(ATRuleParams(bar: args.bar, lookback: args.lookback, parameters: args.parameters)) {
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

