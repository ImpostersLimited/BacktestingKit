import Foundation

public typealias GMBar = ATBar
public typealias GMPosition = ATPosition
public typealias GMStrategy = ATStrategy

public struct GMParameterBucket: Codable, Equatable {
    public var values: [String: Double]
    public init(values: [String: Double] = [:]) {
        self.values = values
    }
}

public struct GMRuleParams {
    public var bar: GMBar
    public var lookback: [GMBar]
    public var parameters: [String: Double]
}

public struct GMOpenPositionRuleArgs {
    public var entryPrice: Double
    public var position: GMPosition
    public var bar: GMBar
    public var lookback: [GMBar]
    public var parameters: [String: Double]
}

public typealias GMEntryRuleFn = (_ enter: EnterPositionFn, _ args: GMRuleParams) -> Void
public typealias GMExitRuleFn = (_ exit: ExitPositionFn, _ args: GMOpenPositionRuleArgs) -> Void
public typealias GMStopLossFn = (_ args: GMOpenPositionRuleArgs) -> Double
public typealias GMProfitTargetFn = (_ args: GMOpenPositionRuleArgs) -> Double

