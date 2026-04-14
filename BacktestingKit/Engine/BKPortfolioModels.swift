import Foundation

/// Allocation mode applied to portfolio sleeves before aggregation.
public enum BKPortfolioAllocationMode: String, Codable, Equatable, Sendable {
    case explicit
    case sleeveWeights
    case riskParity
    case riskOnRiskOff
}

/// Input describing how the portfolio should resolve sleeve weights.
public struct BKPortfolioAllocationInput: Codable, Equatable, Sendable {
    /// Allocation mode associated with this value.
    public var mode: BKPortfolioAllocationMode
    /// Explicit sleeve weights when `.explicit` is used.
    public var explicitWeights: [Double]?
    /// Index of the risk-on sleeve when `.riskOnRiskOff` is used.
    public var riskOnIndex: Int?
    /// Index of the defensive sleeve when `.riskOnRiskOff` is used.
    public var riskOffIndex: Int?

    /// Creates a new instance.
    public init(
        mode: BKPortfolioAllocationMode,
        explicitWeights: [Double]? = nil,
        riskOnIndex: Int? = nil,
        riskOffIndex: Int? = nil
    ) {
        self.mode = mode
        self.explicitWeights = explicitWeights
        self.riskOnIndex = riskOnIndex
        self.riskOffIndex = riskOffIndex
    }
}

public extension BKPortfolioAllocationInput {
    /// Portfolio weights are resolved from caller-supplied explicit weights.
    static func explicit(_ weights: [Double]) -> BKPortfolioAllocationInput {
        BKPortfolioAllocationInput(
            mode: .explicit,
            explicitWeights: weights
        )
    }

    /// Portfolio weights are resolved from each sleeve's `targetWeight`.
    static var sleeveWeights: BKPortfolioAllocationInput {
        BKPortfolioAllocationInput(mode: .sleeveWeights)
    }

    /// Portfolio weights are resolved from inverse realized volatility.
    static var riskParity: BKPortfolioAllocationInput {
        BKPortfolioAllocationInput(mode: .riskParity)
    }

    /// Portfolio weights are resolved from the selected risk-on and defensive sleeves.
    static func riskOnRiskOff(
        riskOnIndex: Int = 0,
        riskOffIndex: Int = 1
    ) -> BKPortfolioAllocationInput {
        BKPortfolioAllocationInput(
            mode: .riskOnRiskOff,
            riskOnIndex: riskOnIndex,
            riskOffIndex: riskOffIndex
        )
    }
}

/// Rebalance mode for additive portfolio aggregation workflows.
public enum BKPortfolioRebalanceMode: String, Codable, Equatable, Sendable {
    case none
    case periodic
    case manual
}

/// Supported periodic rebalance frequencies for additive portfolio workflows.
public enum BKPortfolioRebalanceFrequency: String, Codable, Equatable, Sendable {
    case weekly
    case monthly
    case quarterly
}

/// Policy describing if and when portfolio weights should be re-applied.
public struct BKPortfolioRebalancePolicy: Codable, Equatable, Sendable {
    /// Rebalance mode associated with this value.
    public var mode: BKPortfolioRebalanceMode
    /// Periodic rebalance frequency when `.periodic` is used.
    public var frequency: BKPortfolioRebalanceFrequency?
    /// Explicit rebalance dates when `.manual` is used.
    public var manualDates: [Date]

    /// Creates a new instance.
    public init(
        mode: BKPortfolioRebalanceMode,
        frequency: BKPortfolioRebalanceFrequency? = nil,
        manualDates: [Date] = []
    ) {
        self.mode = mode
        self.frequency = frequency
        self.manualDates = manualDates.sorted()
    }
}

public extension BKPortfolioRebalancePolicy {
    /// Leaves resolved weights untouched after the initial allocation.
    static var none: BKPortfolioRebalancePolicy {
        BKPortfolioRebalancePolicy(mode: .none)
    }

    /// Re-applies resolved weights on a periodic cadence.
    static func periodic(_ frequency: BKPortfolioRebalanceFrequency) -> BKPortfolioRebalancePolicy {
        BKPortfolioRebalancePolicy(
            mode: .periodic,
            frequency: frequency
        )
    }

    /// Re-applies resolved weights on a caller-defined set of dates.
    static func manual(_ dates: [Date]) -> BKPortfolioRebalancePolicy {
        BKPortfolioRebalancePolicy(
            mode: .manual,
            manualDates: dates
        )
    }
}

/// A single preset-backed sleeve request for additive portfolio orchestration.
public struct BKPortfolioSleeveRequest: Codable, Equatable, Sendable {
    /// Sleeve identifier associated with this value.
    public var symbol: String
    /// CSV payload associated with this value.
    public var csv: String
    /// Preset associated with this value.
    public var preset: BKPresetCatalog
    /// Date format string used while parsing or formatting input.
    public var dateFormat: String
    /// Whether the input should be reversed into chronological order.
    public var reverse: Bool
    /// Column mapping associated with this value.
    public var columnMapping: BKCSVColumnMapping?
    /// Caller-supplied target weight associated with this value.
    public var targetWeight: Double?

    /// Creates a new instance.
    public init(
        symbol: String,
        csv: String,
        preset: BKPresetCatalog,
        dateFormat: String = "yyyy-MM-dd",
        reverse: Bool = false,
        columnMapping: BKCSVColumnMapping? = nil,
        targetWeight: Double? = nil
    ) {
        self.symbol = symbol
        self.csv = csv
        self.preset = preset
        self.dateFormat = dateFormat
        self.reverse = reverse
        self.columnMapping = columnMapping
        self.targetWeight = targetWeight
    }
}

/// Canonical request payload for additive portfolio orchestration.
public struct BKPortfolioRequest: Codable, Equatable, Sendable {
    /// Portfolio identifier associated with this value.
    public var portfolioID: String
    /// Sleeve requests associated with this value.
    public var sleeves: [BKPortfolioSleeveRequest]
    /// Allocation input associated with this value.
    public var allocation: BKPortfolioAllocationInput
    /// Rebalance policy associated with this value.
    public var rebalancePolicy: BKPortfolioRebalancePolicy
    /// Whether to keep aggregating after a sleeve failure.
    public var continueOnFailure: Bool

    /// Creates a new instance.
    public init(
        portfolioID: String = "PORTFOLIO",
        sleeves: [BKPortfolioSleeveRequest],
        allocation: BKPortfolioAllocationInput = .sleeveWeights,
        rebalancePolicy: BKPortfolioRebalancePolicy = .none,
        continueOnFailure: Bool = true
    ) {
        self.portfolioID = portfolioID
        self.sleeves = sleeves
        self.allocation = allocation
        self.rebalancePolicy = rebalancePolicy
        self.continueOnFailure = continueOnFailure
    }
}

/// Execution status for a single sleeve inside a portfolio run.
public enum BKPortfolioSleeveStatus: String, Codable, Equatable, Sendable {
    case succeeded
    case failed
}

/// One resolved rebalance application event.
public struct BKPortfolioRebalanceEvent: Codable, Equatable, Sendable {
    /// Event date associated with this value.
    public var date: Date
    /// Human-readable source associated with this value.
    public var source: String

    /// Creates a new instance.
    public init(date: Date, source: String) {
        self.date = date
        self.source = source
    }
}

/// Per-sleeve result captured by the additive portfolio workflow.
public struct BKPortfolioSleeveRunReport: Codable, Equatable, Sendable {
    /// Sleeve identifier associated with this value.
    public var symbol: String
    /// Preset associated with this value.
    public var preset: BKPresetCatalog
    /// Execution status associated with this value.
    public var status: BKPortfolioSleeveStatus
    /// Requested target weight associated with this value.
    public var requestedWeight: Double?
    /// Resolved normalized weight associated with this value.
    public var resolvedWeight: Double
    /// Realized annualized volatility associated with this value.
    public var annualizedVolatility: Double?
    /// Momentum score associated with this value.
    public var momentumScore: Double?
    /// High-level summary associated with this value.
    public var summary: BKRunSummary?
    /// Structured failure associated with this value.
    public var failure: BKEngineFailure?

    /// Creates a new instance.
    public init(
        symbol: String,
        preset: BKPresetCatalog,
        status: BKPortfolioSleeveStatus,
        requestedWeight: Double? = nil,
        resolvedWeight: Double = 0,
        annualizedVolatility: Double? = nil,
        momentumScore: Double? = nil,
        summary: BKRunSummary? = nil,
        failure: BKEngineFailure? = nil
    ) {
        self.symbol = symbol
        self.preset = preset
        self.status = status
        self.requestedWeight = requestedWeight
        self.resolvedWeight = resolvedWeight
        self.annualizedVolatility = annualizedVolatility
        self.momentumScore = momentumScore
        self.summary = summary
        self.failure = failure
    }
}

/// Aggregate result emitted by additive portfolio orchestration.
public struct BKPortfolioRunReport: Codable, Equatable, Sendable {
    /// Portfolio identifier associated with this value.
    public var portfolioID: String
    /// Allocation input associated with this value.
    public var allocation: BKPortfolioAllocationInput
    /// Rebalance policy associated with this value.
    public var rebalancePolicy: BKPortfolioRebalancePolicy
    /// High-level aggregate summary associated with this value.
    public var summary: BKRunSummary?
    /// Per-sleeve reports associated with this value.
    public var sleeveReports: [BKPortfolioSleeveRunReport]
    /// Structured rebalance events associated with this value.
    public var rebalanceEvents: [BKPortfolioRebalanceEvent]
    /// Failures associated with this value.
    public var failures: [BKEngineFailure]
    /// Number of successful sleeves represented by this value.
    public var succeededSleeveCount: Int
    /// Number of failed sleeves represented by this value.
    public var failedSleeveCount: Int
    /// Whether the run succeeded for at least one sleeve but not all sleeves.
    public var isPartialSuccess: Bool
    /// Whether the run produced an aggregate portfolio summary.
    public var isSuccessful: Bool

    /// Creates a new instance.
    public init(
        portfolioID: String,
        allocation: BKPortfolioAllocationInput,
        rebalancePolicy: BKPortfolioRebalancePolicy,
        summary: BKRunSummary? = nil,
        sleeveReports: [BKPortfolioSleeveRunReport],
        rebalanceEvents: [BKPortfolioRebalanceEvent] = [],
        failures: [BKEngineFailure] = [],
        succeededSleeveCount: Int,
        failedSleeveCount: Int,
        isPartialSuccess: Bool,
        isSuccessful: Bool
    ) {
        self.portfolioID = portfolioID
        self.allocation = allocation
        self.rebalancePolicy = rebalancePolicy
        self.summary = summary
        self.sleeveReports = sleeveReports
        self.rebalanceEvents = rebalanceEvents
        self.failures = failures
        self.succeededSleeveCount = succeededSleeveCount
        self.failedSleeveCount = failedSleeveCount
        self.isPartialSuccess = isPartialSuccess
        self.isSuccessful = isSuccessful
    }
}
