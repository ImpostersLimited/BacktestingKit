// BacktestResult.swift
// Summary of backtest trades and performance

import Foundation

/// Represents `BacktestResult` in the BacktestingKit public API.
public struct BacktestResult {
    /// List of executed trades in the backtest.
    public let trades: [Trade]
    /// Total return over the backtest period.
    public let totalReturn: Double
    /// Annualized return based on the backtest results.
    public let annualizedReturn: Double
    /// Proportion of winning trades (0.0 to 1.0).
    public let winRate: Double
    /// Maximum observed drawdown during the backtest.
    public let maxDrawdown: Double
    /// Sharpe ratio of the strategy's returns.
    public let sharpeRatio: Double
    /// Average return per trade.
    public let avgTradeReturn: Double
    /// Total number of trades executed.
    public let numTrades: Int
    /// Number of winning trades.
    public let numWins: Int
    /// Number of losing trades.
    public let numLosses: Int
    /// Profit factor (gross profit / gross loss).
    public let profitFactor: Double
    /// Expectancy (average expected value per trade).
    public let expectancy: Double

    /// Compound Annual Growth Rate
    public let cagr: Double
    /// Standard deviation of returns
    public let volatility: Double
    /// Sortino ratio
    public let sortinoRatio: Double
    /// Calmar ratio
    public let calmarRatio: Double
    /// Average holding period in days
    public let avgHoldingPeriod: Double
    /// Maximum number of consecutive winning trades
    public let maxConsecutiveWins: Int
    /// Maximum number of consecutive losing trades
    public let maxConsecutiveLosses: Int
    /// Average return of winning trades
    public let avgWin: Double
    /// Average return of losing trades
    public let avgLoss: Double
    /// Kelly criterion
    public let kellyCriterion: Double
    /// Ulcer index
    public let ulcerIndex: Double

    /// Creates a new instance.
    public init(trades: [Trade],
                totalReturn: Double,
                annualizedReturn: Double,
                winRate: Double,
                maxDrawdown: Double,
                sharpeRatio: Double,
                avgTradeReturn: Double,
                numTrades: Int,
                numWins: Int,
                numLosses: Int,
                profitFactor: Double,
                expectancy: Double,
                cagr: Double,
                volatility: Double,
                sortinoRatio: Double,
                calmarRatio: Double,
                avgHoldingPeriod: Double,
                maxConsecutiveWins: Int,
                maxConsecutiveLosses: Int,
                avgWin: Double,
                avgLoss: Double,
                kellyCriterion: Double,
                ulcerIndex: Double) {
        self.trades = trades
        self.totalReturn = totalReturn
        self.annualizedReturn = annualizedReturn
        self.winRate = winRate
        self.maxDrawdown = maxDrawdown
        self.sharpeRatio = sharpeRatio
        self.avgTradeReturn = avgTradeReturn
        self.numTrades = numTrades
        self.numWins = numWins
        self.numLosses = numLosses
        self.profitFactor = profitFactor
        self.expectancy = expectancy
        self.cagr = cagr
        self.volatility = volatility
        self.sortinoRatio = sortinoRatio
        self.calmarRatio = calmarRatio
        self.avgHoldingPeriod = avgHoldingPeriod
        self.maxConsecutiveWins = maxConsecutiveWins
        self.maxConsecutiveLosses = maxConsecutiveLosses
        self.avgWin = avgWin
        self.avgLoss = avgLoss
        self.kellyCriterion = kellyCriterion
        self.ulcerIndex = ulcerIndex
    }
}
