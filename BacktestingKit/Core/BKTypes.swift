import Foundation

public struct User: Codable, Equatable {
    public var devices: [Device]
    public var id: String
    public var instruments: [Instrument]
    public var user_id: String
    public var tier: BKEntitlement
    public var last_updated: Double
}

/// Represents `Device` in the BacktestingKit public API.
public struct Device: Codable, Equatable {
    public var device_id: String
    public var device_type: String
    public var id: String
    public var last_updated: Double
    public var user_id: String
}

/// Represents `Instrument` in the BacktestingKit public API.
public struct Instrument: Codable, Equatable {
    public var pin: Bool
    public var exch: String
    public var exchDisp: String
    public var name: String
    public var type: String
    public var typeDisp: String
    public var config_history: [Config]
    public var optimize_history: [OptimizeResult]
    public var id: String
    public var instrument: String
    public var last_updated: Double
}

/// Represents `Config` in the BacktestingKit public API.
public struct Config: Codable, Equatable {
    public var id: String
    public var transactions: [BKTrade]
    public var active: Bool
    public var created: Double
    public var instrument: String
    public var last_updated: Double
    public var policyConfig: SimulationPolicyConfig
    public var analysis: BKAnalysis
    public var status: SimulationStatus
}

/// Represents `OptimizeResult` in the BacktestingKit public API.
public struct OptimizeResult: Codable, Equatable {
    public var id: String
    public var result: [Config]
    public var policyConfig: OptimizePolicyConfig
    public var last_updated: Double
    public var created: Double
    public var status: SimulationStatus
}

/// Represents `TriggerType` in the BacktestingKit public API.
public enum TriggerType: String, Codable {
    case optimize
    case simulate
}

/// Represents `DynamodbTrigger` in the BacktestingKit public API.
public struct DynamodbTrigger: Codable, Equatable {
    public var uuid: String
    public var type: TriggerType
    public var itemId: String
    public var optimize: [OptimizePolicyConfig]
    public var simulate: [SimulationPolicyConfig]
    public var instrument: String
    public var user_id: String
}

/// Represents `SimulationTimeframe` in the BacktestingKit public API.
public enum SimulationTimeframe: Double, Codable {
    case t0 = 0.0
    case t1 = 1.0
    case t2 = 2.0
    case t3 = 3.0
    case t4 = 4.0
    case t5 = 5.0
    case t6 = 6.0
}

/// Executes `BKAnalysisTypeCheck`.
public func BKAnalysisTypeCheck(_ input: BKAnalysis) -> BKAnalysis {
    var result = input
    result.maxRiskPct = result.maxRiskPct ?? 0
    result.systemQuality = result.systemQuality ?? 0
    return result
}
