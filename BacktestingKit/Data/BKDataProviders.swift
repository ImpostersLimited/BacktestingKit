import Foundation

public struct AlphaVantageRetryPolicy: Equatable, Sendable {
    public var maxAttempts: Int
    public var initialBackoffSeconds: Double

    /// Creates a new instance.
    public init(maxAttempts: Int = 3, initialBackoffSeconds: Double = 1.0) {
        self.maxAttempts = max(1, maxAttempts)
        self.initialBackoffSeconds = max(0.1, initialBackoffSeconds)
    }
}

/// Represents `BKRequestRateLimiter` in the BacktestingKit public API.
public actor BKRequestRateLimiter {
    private let minIntervalNanoseconds: UInt64
    private var lastExecutionTime: UInt64?

    /// Creates a new instance.
    public init(minIntervalSeconds: Double) {
        let normalized = max(0, minIntervalSeconds)
        self.minIntervalNanoseconds = UInt64(normalized * 1_000_000_000)
    }

    /// Executes `acquire`.
    public func acquire() async -> Result<Void, Error> {
        guard minIntervalNanoseconds > 0 else { return .success(()) }
        let now = DispatchTime.now().uptimeNanoseconds
        if let last = lastExecutionTime {
            let elapsed = now >= last ? (now - last) : 0
            if elapsed < minIntervalNanoseconds {
                do {
                    try await Task.sleep(for: .nanoseconds(minIntervalNanoseconds - elapsed))
                } catch {
                    return .failure(error)
                }
            }
        }
        lastExecutionTime = DispatchTime.now().uptimeNanoseconds
        return .success(())
    }
}

/// Defines the `BKV3DataStore` contract used by BacktestingKit.
public protocol BKV3DataStore {
    func getConfigs(instrumentID: String) async -> Result<[BKV3_Config], Error>
    func getSimulationRules(configID: String, ruleType: String) async -> Result<[BKV3_SimulationRule], Error>
    func saveConfig(_ config: BKV3_Config) async -> Result<Void, Error>
    func saveAnalysis(_ analysis: BKV3_AnalysisProfile) async -> Result<Void, Error>
    func saveTrades(_ trades: [BKV3_TradeEntry]) async -> Result<Void, Error>
    func saveSimulationRules(_ rules: [BKV3_SimulationRule]) async -> Result<Void, Error>
    func saveRisks(_ risks: [BKV3_RiskProfile]) async -> Result<Void, Error>
}

/// Defines the `BKRawCsvProvider` contract used by BacktestingKit.
public protocol BKRawCsvProvider {
    func getRawCsv(ticker: String, p1: Double, p2: Double) async -> Result<String, Error>
}

/// Represents `BKCustomCsvProvider` in the BacktestingKit public API.
public struct BKCustomCsvProvider: BKRawCsvProvider, Sendable {
    /// Provides the `Loader` typealias for BacktestingKit interoperability.
    public typealias Loader = @Sendable (_ ticker: String, _ p1: Double, _ p2: Double) async -> Result<String, Error>

    private let loader: Loader

    /// Creates a new instance.
    public init(loader: @escaping Loader) {
        self.loader = loader
    }

    /// Executes `getRawCsv`.
    public func getRawCsv(ticker: String, p1: Double, p2: Double) async -> Result<String, Error> {
        await loader(ticker, p1, p2)
    }
}

/// Represents `BKCsvCacheConfiguration` in the BacktestingKit public API.
