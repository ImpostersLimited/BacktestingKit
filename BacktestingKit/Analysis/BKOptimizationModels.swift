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
    public var name: String
    public var startingValue: Double
    public var endingValue: Double
    public var stepSize: Double
}

/// Represents `OptimizationType` in the BacktestingKit public API.
public enum OptimizationType: String, Codable {
    case grid
    case hillClimb = "hill-climb"
}

/// Represents `OptimizationOptions` in the BacktestingKit public API.
public struct OptimizationOptions: Codable, Equatable {
    public var searchDirection: OptimizeSearchDirection?
    public var optimizationType: OptimizationType?
    public var recordAllResults: Bool?
    public var randomSeed: Double?
    public var numStartingPoints: Int?
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
    public var params: ParameterT
    public var result: Double
    public var numTrades: Int
}

/// Represents `OptimizationResult` in the BacktestingKit public API.
public struct OptimizationResult<ParameterT: Codable & Equatable>: Codable, Equatable {
    public var bestResult: Double
    public var bestParameterValues: ParameterT
    public var allResults: [OptimizationIterationResult<ParameterT>]?
    public var durationMS: Double?
}

/// Represents `WalkForwardOptimizationResult` in the BacktestingKit public API.
public struct WalkForwardOptimizationResult: Codable, Equatable {
    public var trades: [BKTrade]
}

/// Represents `MonteCarloOptions` in the BacktestingKit public API.
public struct MonteCarloOptions: Codable, Equatable {
    public var randomSeed: Double?
    /// Creates a new instance.
    public init(randomSeed: Double? = nil) {
        self.randomSeed = randomSeed
    }
}
