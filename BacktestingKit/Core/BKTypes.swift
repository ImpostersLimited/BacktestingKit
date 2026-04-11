import Foundation

/// User profile aggregate containing tracked devices and instruments.
public struct User: Codable, Equatable {
    /// Devices associated with this value.
    public var devices: [Device]
    /// Stable identifier for this value.
    public var id: String
    /// Instruments associated with this value.
    public var instruments: [Instrument]
    /// Identifier associated with this value.
    public var user_id: String
    /// Tier associated with this value.
    public var tier: BKEntitlement
    /// Last updated associated with this value.
    public var last_updated: Double
}

/// Represents `Device` in the BacktestingKit public API.
public struct Device: Codable, Equatable {
    /// Identifier associated with this value.
    public var device_id: String
    /// Device type associated with this value.
    public var device_type: String
    /// Stable identifier for this value.
    public var id: String
    /// Last updated associated with this value.
    public var last_updated: Double
    /// Identifier associated with this value.
    public var user_id: String
}

/// Represents `Instrument` in the BacktestingKit public API.
public struct Instrument: Codable, Equatable {
    /// Pin associated with this value.
    public var pin: Bool
    /// Exch associated with this value.
    public var exch: String
    /// Exch disp associated with this value.
    public var exchDisp: String
    /// Name associated with this value.
    public var name: String
    /// Type associated with this value.
    public var type: String
    /// Type disp associated with this value.
    public var typeDisp: String
    /// Configuration associated with this value.
    public var config_history: [Config]
    /// Optimize history associated with this value.
    public var optimize_history: [OptimizeResult]
    /// Stable identifier for this value.
    public var id: String
    /// Instrument associated with this value.
    public var instrument: String
    /// Last updated associated with this value.
    public var last_updated: Double
}

/// Represents `Config` in the BacktestingKit public API.
public struct Config: Codable, Equatable {
    /// Stable identifier for this value.
    public var id: String
    /// Transactions associated with this value.
    public var transactions: [BKTrade]
    /// Active associated with this value.
    public var active: Bool
    /// Created associated with this value.
    public var created: Double
    /// Instrument associated with this value.
    public var instrument: String
    /// Last updated associated with this value.
    public var last_updated: Double
    /// Configuration associated with this value.
    public var policyConfig: SimulationPolicyConfig
    /// Analysis associated with this value.
    public var analysis: BKAnalysis
    /// Current status associated with this value.
    public var status: SimulationStatus
}

/// Represents `OptimizeResult` in the BacktestingKit public API.
public struct OptimizeResult: Codable, Equatable {
    /// Stable identifier for this value.
    public var id: String
    /// Result associated with this value.
    public var result: [Config]
    /// Configuration associated with this value.
    public var policyConfig: OptimizePolicyConfig
    /// Last updated associated with this value.
    public var last_updated: Double
    /// Created associated with this value.
    public var created: Double
    /// Current status associated with this value.
    public var status: SimulationStatus
}

/// Represents `TriggerType` in the BacktestingKit public API.
public enum TriggerType: String, Codable {
    case optimize
    case simulate
}

/// Represents `DynamodbTrigger` in the BacktestingKit public API.
public struct DynamodbTrigger: Codable, Equatable {
    /// Stable identifier for this value.
    public var uuid: String
    /// Type associated with this value.
    public var type: TriggerType
    /// Item ID associated with this value.
    public var itemId: String
    /// Optimize associated with this value.
    public var optimize: [OptimizePolicyConfig]
    /// Simulate associated with this value.
    public var simulate: [SimulationPolicyConfig]
    /// Instrument associated with this value.
    public var instrument: String
    /// Identifier associated with this value.
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
