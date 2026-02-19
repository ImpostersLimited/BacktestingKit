import Foundation

/// Built-in deterministic strategy variants for generated scenario runs.
public enum BKScenarioStrategy: String, Codable, Equatable {
    case smaCrossover
    case emaFastSlow
}

/// Configuration for a deterministic synthetic market scenario.
public struct BKScenarioConfig: Codable, Equatable {
    /// Logical symbol label used for reporting.
    public var symbol: String
    /// Number of generated bars.
    public var barCount: Int
    /// Initial close price.
    public var startingPrice: Double
    /// Deterministic drift applied per bar.
    public var driftPerBar: Double
    /// Random shock amplitude.
    public var volatility: Double
    /// Deterministic RNG seed.
    public var seed: Double
    /// Built-in strategy variant executed on generated candles.
    public var strategy: BKScenarioStrategy

    /// Creates a scenario configuration.
    public init(
        symbol: String = "SCENARIO",
        barCount: Int = 252,
        startingPrice: Double = 100,
        driftPerBar: Double = 0.0004,
        volatility: Double = 0.01,
        seed: Double = 42,
        strategy: BKScenarioStrategy = .smaCrossover
    ) {
        self.symbol = symbol
        self.barCount = barCount
        self.startingPrice = startingPrice
        self.driftPerBar = driftPerBar
        self.volatility = volatility
        self.seed = seed
        self.strategy = strategy
    }
}

/// Output from a deterministic scenario run.
public struct BKScenarioResult {
    /// Scenario configuration used for generation.
    public var config: BKScenarioConfig
    /// Generated candles in chronological order.
    public var candles: [Candlestick]
    /// Backtest output for configured strategy.
    public var backtest: BacktestResult

    /// Creates a scenario result.
    public init(config: BKScenarioConfig, candles: [Candlestick], backtest: BacktestResult) {
        self.config = config
        self.candles = candles
        self.backtest = backtest
    }
}

/// Scenario generation and deterministic replay helpers.
public enum BKScenarioTool {
    /// Generates synthetic candles and runs a deterministic preset strategy.
    ///
    /// - Parameter config: Scenario configuration.
    /// - Returns: Generated candles and backtest result.
    public static func run(config: BKScenarioConfig) -> BKScenarioResult {
        let candles = generateCandles(config: config)
        let manager = BacktestingKitManager()
        let backtest: BacktestResult
        switch config.strategy {
        case .smaCrossover:
            backtest = manager.backtestSMACrossover(candles: candles, fast: 5, slow: 20)
        case .emaFastSlow:
            backtest = manager.backtestEMAFastSlowWithATRStop(candles: candles, fastPeriod: 12, slowPeriod: 26)
        }
        return BKScenarioResult(config: config, candles: candles, backtest: backtest)
    }

    /// Generates deterministic synthetic OHLCV data.
    ///
    /// - Parameter config: Scenario configuration.
    /// - Returns: Chronological synthetic candles.
    public static func generateCandles(config: BKScenarioConfig) -> [Candlestick] {
        let effectiveCount = max(2, config.barCount)
        let random = Random(seed: config.seed)
        var output: [Candlestick] = []
        output.reserveCapacity(effectiveCount)

        var close = max(0.01, config.startingPrice)
        var dayOffset = 0
        for _ in 0..<effectiveCount {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date(timeIntervalSince1970: 0)) ?? Date(timeIntervalSince1970: 0)
            let shock = random.getReal(min: -config.volatility, max: config.volatility)
            let move = config.driftPerBar + shock
            let nextClose = max(0.01, close * (1.0 + move))
            let spread = max(0.001, abs(nextClose - close) * 0.8 + close * 0.002)
            let high = max(close, nextClose) + spread
            let low = max(0.001, min(close, nextClose) - spread)
            let volume = max(1.0, 1_000_000.0 * (1.0 + random.getReal(min: -0.2, max: 0.2)))
            output.append(
                Candlestick(
                    date: date,
                    open: close,
                    high: high,
                    low: low,
                    close: nextClose,
                    volume: volume
                )
            )
            close = nextClose
            dayOffset += 1
        }
        return output
    }
}
