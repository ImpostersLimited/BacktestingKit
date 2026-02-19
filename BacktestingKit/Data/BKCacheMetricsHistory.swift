import Foundation

/// Defines the `BKCacheMetricsSnapshotStoring` contract used by BacktestingKit.
public protocol BKCacheMetricsSnapshotStoring {
    func allSnapshots() -> [BKCacheMetricsSnapshot]
    func persist(to url: URL) -> Result<Void, Error>
    func appendSnapshot(_ snapshot: BKCacheMetricsSnapshot)
}

public final class BKCacheMetricsHistory: BKCacheMetricsSnapshotStoring {
    private let capacity: Int
    private var snapshots: [BKCacheMetricsSnapshot]
    private var headIndex: Int
    private let lock = NSLock()

    /// Creates a new instance.
    public init(capacity: Int = 64) {
        self.capacity = max(1, capacity)
        self.snapshots = []
        self.headIndex = 0
    }

    /// Executes `allSnapshots`.
    public func allSnapshots() -> [BKCacheMetricsSnapshot] {
        lock.lock()
        defer { lock.unlock() }
        guard snapshots.count == capacity, headIndex > 0 else {
            return snapshots
        }
        var ordered: [BKCacheMetricsSnapshot] = []
        ordered.reserveCapacity(snapshots.count)
        ordered.append(contentsOf: snapshots[headIndex...])
        ordered.append(contentsOf: snapshots[..<headIndex])
        return ordered
    }

    /// Executes `persist`.
    public func persist(to url: URL) -> Result<Void, Error> {
        do {
            let data = try JSONEncoder().encode(allSnapshots())
            try data.write(to: url)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    /// Executes `appendSnapshot`.
    public func appendSnapshot(_ snapshot: BKCacheMetricsSnapshot) {
        lock.lock()
        if snapshots.count < capacity {
            snapshots.append(snapshot)
            lock.unlock()
            return
        }

        snapshots[headIndex] = snapshot
        headIndex = (headIndex + 1) % capacity
        lock.unlock()
    }
}
