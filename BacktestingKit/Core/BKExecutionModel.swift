import Foundation

/// Defines the `BKSlippageModel` contract used by BacktestingKit.
public protocol BKSlippageModel {
    func slippagePrice(referencePrice: Double, quantity: Double, isBuy: Bool) -> Double
}

/// Defines the `BKCommissionModel` contract used by BacktestingKit.
public protocol BKCommissionModel {
    func commission(notional: Double, quantity: Double) -> Double
}

/// Represents `BKNoSlippageModel` in the BacktestingKit public API.
public struct BKNoSlippageModel: BKSlippageModel {
    /// Creates a new instance.
    public init() {}
    /// Executes `slippagePrice`.
    public func slippagePrice(referencePrice: Double, quantity: Double, isBuy: Bool) -> Double {
        referencePrice
    }
}

/// Represents `BKFixedBpsSlippageModel` in the BacktestingKit public API.
public struct BKFixedBpsSlippageModel: BKSlippageModel {
    /// Bps associated with this value.
    public let bps: Double

    /// Creates a new instance.
    public init(bps: Double) {
        self.bps = max(0, bps)
    }

    /// Executes `slippagePrice`.
    public func slippagePrice(referencePrice: Double, quantity: Double, isBuy: Bool) -> Double {
        let adjustment = referencePrice * (bps / 10_000.0)
        return isBuy ? (referencePrice + adjustment) : (referencePrice - adjustment)
    }
}

/// Represents `BKNoCommissionModel` in the BacktestingKit public API.
public struct BKNoCommissionModel: BKCommissionModel {
    /// Creates a new instance.
    public init() {}
    /// Executes `commission`.
    public func commission(notional: Double, quantity: Double) -> Double { 0 }
}

/// Represents `BKFixedPlusPercentCommissionModel` in the BacktestingKit public API.
public struct BKFixedPlusPercentCommissionModel: BKCommissionModel {
    /// Fixed per order associated with this value.
    public let fixedPerOrder: Double
    /// Percent of notional associated with this value.
    public let percentOfNotional: Double

    /// Creates a new instance.
    public init(fixedPerOrder: Double, percentOfNotional: Double) {
        self.fixedPerOrder = max(0, fixedPerOrder)
        self.percentOfNotional = max(0, percentOfNotional)
    }

    /// Executes `commission`.
    public func commission(notional: Double, quantity: Double) -> Double {
        fixedPerOrder + (abs(notional) * percentOfNotional)
    }
}

/// Represents `BKExecutionAdjustedTrade` in the BacktestingKit public API.
public struct BKExecutionAdjustedTrade: Equatable, Codable {
    /// Entry date associated with this value.
    public let entryDate: Date
    /// Exit date associated with this value.
    public let exitDate: Date
    /// Entry price associated with this value.
    public let entryPrice: Double
    /// Exit price associated with this value.
    public let exitPrice: Double
    /// Quantity associated with this value.
    public let quantity: Double
    /// Gross pnl associated with this value.
    public let grossPnl: Double
    /// Net pnl associated with this value.
    public let netPnl: Double
    /// Commissions associated with this value.
    public let commissions: Double

    /// Creates a new instance.
    public init(
        entryDate: Date,
        exitDate: Date,
        entryPrice: Double,
        exitPrice: Double,
        quantity: Double,
        grossPnl: Double,
        netPnl: Double,
        commissions: Double
    ) {
        self.entryDate = entryDate
        self.exitDate = exitDate
        self.entryPrice = entryPrice
        self.exitPrice = exitPrice
        self.quantity = quantity
        self.grossPnl = grossPnl
        self.netPnl = netPnl
        self.commissions = commissions
    }
}
