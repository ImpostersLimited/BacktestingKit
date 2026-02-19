import Foundation

/// Represents `BKCacheMetricsSnapshot` in the BacktestingKit public API.
public struct BKCacheMetricsSnapshot: Equatable, Codable {
    public let stats: BKCsvCacheStats
    public let timestamp: Date

    /// Creates a new instance.
    public init(stats: BKCsvCacheStats, timestamp: Date = Date()) {
        self.stats = stats
        self.timestamp = timestamp
    }
}

/// Defines the `BKCacheMetricsReporting` contract used by BacktestingKit.
public protocol BKCacheMetricsReporting {
    func snapshot() -> BKCacheMetricsSnapshot
    func streamUpdates() -> AsyncStream<BKCacheMetricsSnapshot>
}

public final class BKCacheMetricsReporter: BKCacheMetricsReporting {
    private let provider: BKCachedCsvProvider
    private let lock = NSLock()
    private var lastSnapshot: BKCacheMetricsSnapshot
    private var continuation: AsyncStream<BKCacheMetricsSnapshot>.Continuation?
    private var observerID: UUID?
    private let history: (any BKCacheMetricsSnapshotStoring)?

    /// Creates a new instance.
    public init(provider: BKCachedCsvProvider, history: (any BKCacheMetricsSnapshotStoring)? = nil) {
        self.provider = provider
        self.lastSnapshot = BKCacheMetricsSnapshot(stats: provider.metrics)
        self.history = history
        Task.detached { [weak self] in
            guard let self = self else { return }
            let id = await self.provider.cache.addObserver { [weak self] stats in
                self?.push(stats)
            }
            self.setObserverID(id)
        }
    }

    /// Executes `snapshot`.
    public func snapshot() -> BKCacheMetricsSnapshot {
        lock.lock(); defer { lock.unlock() }
        return lastSnapshot
    }

    /// Executes `streamUpdates`.
    public func streamUpdates() -> AsyncStream<BKCacheMetricsSnapshot> {
        AsyncStream { continuation in
            lock.lock()
            self.continuation = continuation
            continuation.yield(self.lastSnapshot)
            lock.unlock()

            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.lock.lock()
                self.continuation = nil
                self.lock.unlock()
            }
        }
    }

    deinit {
        if let id = observerID {
            let cache = provider.cache
            Task.detached {
                await cache.removeObserver(id)
            }
        }
        continuation?.finish()
    }

    private func push(_ stats: BKCsvCacheStats) {
        lock.lock()
        let snapshot = BKCacheMetricsSnapshot(stats: stats, timestamp: Date())
        lastSnapshot = snapshot
        let cont = continuation
        lock.unlock()
        history?.appendSnapshot(snapshot)
        cont?.yield(snapshot)
    }

    private func setObserverID(_ id: UUID) {
        lock.lock()
        observerID = id
        lock.unlock()
    }
}
