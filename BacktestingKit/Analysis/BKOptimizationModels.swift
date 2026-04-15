import Foundation

/// Provides the `ObjectiveFn` typealias for BacktestingKit interoperability.
public typealias ObjectiveFn = (_ trades: [BKTrade]) -> Double

/// Represents `OptimizeSearchDirection` in the BacktestingKit public API.
public enum OptimizeSearchDirection: String, Codable {
    case max
    case min
}

/// Represents `ParameterDef` in the BacktestingKit public API.
public struct ParameterDef: Codable, Equatable {
    /// Name associated with this value.
    public var name: String
    /// Starting value associated with this value.
    public var startingValue: Double
    /// Ending value associated with this value.
    public var endingValue: Double
    /// Step size associated with this value.
    public var stepSize: Double
}

/// Represents `OptimizationType` in the BacktestingKit public API.
public enum OptimizationType: String, Codable {
    case grid
    case hillClimb = "hill-climb"
}

/// Represents `OptimizationOptions` in the BacktestingKit public API.
public struct OptimizationOptions: Codable, Equatable {
    /// Search direction associated with this value.
    public var searchDirection: OptimizeSearchDirection?
    /// Optimization type associated with this value.
    public var optimizationType: OptimizationType?
    /// Whether to record all results.
    public var recordAllResults: Bool?
    /// Random seed associated with this value.
    public var randomSeed: Double?
    /// Number starting points represented by this value.
    public var numStartingPoints: Int?
    /// Whether to record duration.
    public var recordDuration: Bool?

    /// Creates a new instance.
    public init(
        searchDirection: OptimizeSearchDirection? = nil,
        optimizationType: OptimizationType? = nil,
        recordAllResults: Bool? = nil,
        randomSeed: Double? = nil,
        numStartingPoints: Int? = nil,
        recordDuration: Bool? = nil
    ) {
        self.searchDirection = searchDirection
        self.optimizationType = optimizationType
        self.recordAllResults = recordAllResults
        self.randomSeed = randomSeed
        self.numStartingPoints = numStartingPoints
        self.recordDuration = recordDuration
    }
}

/// Represents `OptimizationIterationResult` in the BacktestingKit public API.
public struct OptimizationIterationResult<ParameterT: Codable & Equatable>: Codable, Equatable {
    /// Params associated with this value.
    public var params: ParameterT
    /// Result associated with this value.
    public var result: Double
    /// Number trades represented by this value.
    public var numTrades: Int
}

/// Represents `OptimizationResult` in the BacktestingKit public API.
public struct OptimizationResult<ParameterT: Codable & Equatable>: Codable, Equatable {
    /// Best result associated with this value.
    public var bestResult: Double
    /// Best parameter values associated with this value.
    public var bestParameterValues: ParameterT
    /// All results associated with this value.
    public var allResults: [OptimizationIterationResult<ParameterT>]?
    /// Duration ms associated with this value.
    public var durationMS: Double?
}

/// Represents `WalkForwardOptimizationResult` in the BacktestingKit public API.
public struct WalkForwardOptimizationResult: Codable, Equatable {
    /// Trades associated with this value.
    public var trades: [BKTrade]
}

/// Represents `MonteCarloOptions` in the BacktestingKit public API.
public struct MonteCarloOptions: Codable, Equatable {
    /// Random seed associated with this value.
    public var randomSeed: Double?
    /// Creates a new instance.
    public init(randomSeed: Double? = nil) {
        self.randomSeed = randomSeed
    }
}
