import Foundation

public struct BKCsvCacheConfiguration: Equatable, Codable {
    public var maxEntries: Int
    public var timeToLiveSeconds: TimeInterval

    /// Creates a new instance.
    public init(maxEntries: Int = 8, timeToLiveSeconds: TimeInterval = 300) {
        self.maxEntries = max(1, maxEntries)
        self.timeToLiveSeconds = max(1, timeToLiveSeconds)
    }
}

/// Represents `BKCsvCacheStats` in the BacktestingKit public API.
public struct BKCsvCacheStats: Equatable, Codable {
    public var hits: Int
    public var misses: Int
    public var entries: Int

    public var hitRate: Double {
        let total = hits + misses
        guard total > 0 else { return 0 }
        return Double(hits) / Double(total)
    }

    /// Creates a new instance.
    public init(hits: Int = 0, misses: Int = 0, entries: Int = 0) {
        self.hits = hits
        self.misses = misses
        self.entries = entries
    }
}

private struct BKCsvCacheKey: Hashable {
    let ticker: String
    let p1: Double
    let p2: Double
}

private struct BKCsvCacheEntry {
    let value: String
    let insertedAt: Date
    let lastAccessAt: Date
}

actor BKInMemoryCsvCache {
    private let configuration: BKCsvCacheConfiguration
    private var storage: [BKCsvCacheKey: BKCsvCacheEntry] = [:]
    private var hits = 0
    private var misses = 0

    var observers: [UUID: (BKCsvCacheStats) -> Void] = [:]

    init(configuration: BKCsvCacheConfiguration) {
        self.configuration = configuration
    }

    fileprivate func read(key: BKCsvCacheKey, now: Date = Date()) -> String? {
        guard let entry = storage[key] else {
            misses += 1
            notifyObservers()
            return nil
        }
        if now.timeIntervalSince(entry.insertedAt) > configuration.timeToLiveSeconds {
            storage.removeValue(forKey: key)
            misses += 1
            return nil
        }
        hits += 1
        storage[key] = BKCsvCacheEntry(value: entry.value, insertedAt: entry.insertedAt, lastAccessAt: now)
        return entry.value
    }

    fileprivate func write(key: BKCsvCacheKey, value: String, now: Date = Date()) {
        storage[key] = BKCsvCacheEntry(value: value, insertedAt: now, lastAccessAt: now)
        evictIfNeeded()
        notifyObservers()
    }

    func clear() {
        storage.removeAll(keepingCapacity: true)
        hits = 0
        misses = 0
        notifyObservers()
    }

    func stats() -> BKCsvCacheStats {
        BKCsvCacheStats(hits: hits, misses: misses, entries: storage.count)
    }

    func addObserver(_ callback: @escaping (BKCsvCacheStats) -> Void) -> UUID {
        let id = UUID()
        observers[id] = callback
        callback(stats())
        return id
    }

    func removeObserver(_ id: UUID) {
        observers.removeValue(forKey: id)
    }

    private func notifyObservers() {
        let snapshot = stats()
        for callback in observers.values {
            callback(snapshot)
        }
    }

    private func evictIfNeeded() {
        guard storage.count > configuration.maxEntries else { return }
        let sortedByLastAccess = storage.sorted { $0.value.lastAccessAt < $1.value.lastAccessAt }
        let overflow = storage.count - configuration.maxEntries
        for index in 0..<overflow {
            storage.removeValue(forKey: sortedByLastAccess[index].key)
        }
    }
}

public final class BKCachedCsvProvider: BKRawCsvProvider {
    private let wrapped: BKRawCsvProvider
    let cache: BKInMemoryCsvCache

    private var observerID: UUID?
    private var lastMetrics: BKCsvCacheStats
    private let metricsLock = NSLock()
    public let metricsHistory: any BKCacheMetricsSnapshotStoring

    public var metrics: BKCsvCacheStats {
        metricsLock.lock()
        defer { metricsLock.unlock() }
        return lastMetrics
    }

    /// Creates a new instance.
    public init(
        wrapped: BKRawCsvProvider,
        configuration: BKCsvCacheConfiguration = BKCsvCacheConfiguration(),
        history: any BKCacheMetricsSnapshotStoring = BKCacheMetricsHistory()
    ) {
        self.wrapped = wrapped
        self.cache = BKInMemoryCsvCache(configuration: configuration)
        self.metricsHistory = history
        self.lastMetrics = BKCsvCacheStats(entries: 0)
        Task.detached { [weak self] in
            guard let self = self else { return }
            let id = await self.cache.addObserver { [weak self] stats in
                self?.updateMetrics(stats)
            }
            self.setObserverID(id)
        }
    }

    /// Executes `getRawCsv`.
    public func getRawCsv(ticker: String, p1: Double, p2: Double) async -> Result<String, Error> {
        let normalizedTicker = ticker.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = BKCsvCacheKey(ticker: normalizedTicker, p1: p1, p2: p2)
        if let cached = await cache.read(key: key) {
            return .success(cached)
        }
        let result = await wrapped.getRawCsv(ticker: normalizedTicker, p1: p1, p2: p2)
        if case .success(let value) = result {
            await cache.write(key: key, value: value)
        }
        return result
    }

    /// Executes `clearCache`.
    public func clearCache() async {
        await cache.clear()
    }

    deinit {
        if let id = observerID {
            let cache = self.cache
            Task {
                await cache.removeObserver(id)
            }
        }
    }

    /// Executes `cacheStats`.
    public func cacheStats() async -> BKCsvCacheStats {
        await cache.stats()
    }

    private func updateMetrics(_ stats: BKCsvCacheStats) {
        metricsLock.lock()
        lastMetrics = stats
        metricsLock.unlock()
    }

    private func setObserverID(_ id: UUID) {
        metricsLock.lock()
        observerID = id
        metricsLock.unlock()
    }
}

/// Represents `AlphaVantageClient` in the BacktestingKit public API.
