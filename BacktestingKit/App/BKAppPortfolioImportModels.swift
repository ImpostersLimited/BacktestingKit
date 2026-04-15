import Foundation

/// App-facing basket input for portfolio CSV review and execution workflows.
public struct BKAppPortfolioImportItem: Codable, Equatable, Sendable {
    /// Sleeve identifier associated with this value.
    public var symbol: String
    /// CSV payload associated with this value.
    public var csv: String
    /// Preset associated with this value.
    public var preset: BKPresetCatalog
    /// Caller-supplied target weight associated with this value.
    public var targetWeight: Double?

    /// Creates a new instance.
    public init(
        symbol: String,
        csv: String,
        preset: BKPresetCatalog,
        targetWeight: Double? = nil
    ) {
        self.symbol = symbol
        self.csv = csv
        self.preset = preset
        self.targetWeight = targetWeight
    }
}

/// Per-sleeve review output for app-facing portfolio import flows.
public struct BKAppPortfolioImportItemState: Equatable {
    /// Basket request associated with this value.
    public var request: BKAppPortfolioImportItem
    /// Resolved single-sleeve screen state associated with this value.
    public var screenState: BKAppCSVImportScreenState

    /// Creates a new instance.
    public init(
        request: BKAppPortfolioImportItem,
        screenState: BKAppCSVImportScreenState
    ) {
        self.request = request
        self.screenState = screenState
    }
}

/// Grouped issue section for an app-facing portfolio import review screen.
public struct BKAppPortfolioImportIssueSection: Codable, Equatable, Sendable {
    /// Sleeve identifier associated with this value.
    public var symbol: String
    /// Title associated with this value.
    public var title: String
    /// Items associated with this value.
    public var items: [BKAppCSVImportIssueItem]

    /// Creates a new instance.
    public init(
        symbol: String,
        title: String,
        items: [BKAppCSVImportIssueItem]
    ) {
        self.symbol = symbol
        self.title = title
        self.items = items
    }
}

/// Aggregated screen-state payload for app-facing portfolio review flows.
public struct BKAppPortfolioImportScreenState: Equatable {
    /// Portfolio identifier associated with this value.
    public var portfolioID: String
    /// Reviewed sleeve states associated with this value.
    public var sleeves: [BKAppPortfolioImportItemState]
    /// Allocation input associated with this value.
    public var allocation: BKPortfolioAllocationInput
    /// Rebalance policy associated with this value.
    public var rebalancePolicy: BKPortfolioRebalancePolicy
    /// Issues associated with this value.
    public var issues: [BKAppPortfolioImportIssueSection]
    /// Current status associated with this value.
    public var status: BKAppCSVImportScreenStatus
    /// Whether the workflow can continue without additional user input.
    public var isReadyToContinue: Bool

    /// Creates a new instance.
    public init(
        portfolioID: String,
        sleeves: [BKAppPortfolioImportItemState],
        allocation: BKPortfolioAllocationInput,
        rebalancePolicy: BKPortfolioRebalancePolicy,
        issues: [BKAppPortfolioImportIssueSection],
        status: BKAppCSVImportScreenStatus,
        isReadyToContinue: Bool
    ) {
        self.portfolioID = portfolioID
        self.sleeves = sleeves
        self.allocation = allocation
        self.rebalancePolicy = rebalancePolicy
        self.issues = issues
        self.status = status
        self.isReadyToContinue = isReadyToContinue
    }
}

/// Result of confirming per-sleeve review settings and executing a portfolio run.
public struct BKAppPortfolioConfirmedRunReport: Equatable {
    /// Confirmed per-symbol settings associated with this value.
    public var confirmedSettingsBySymbol: [String: BKAppCSVConfirmedImportSettings]
    /// Portfolio run associated with this value.
    public var run: BKPortfolioRunReport

    /// Creates a new instance.
    public init(
        confirmedSettingsBySymbol: [String: BKAppCSVConfirmedImportSettings],
        run: BKPortfolioRunReport
    ) {
        self.confirmedSettingsBySymbol = confirmedSettingsBySymbol
        self.run = run
    }
}
