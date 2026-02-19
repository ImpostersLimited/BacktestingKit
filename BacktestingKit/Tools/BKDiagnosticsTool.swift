import Foundation

/// Event kind emitted by diagnostics instrumentation.
public enum BKDiagnosticEventKind: String, Codable, Equatable {
    case validationStarted
    case validationFailed
    case parsingStarted
    case parsingCompleted
    case simulationStarted
    case simulationCompleted
    case simulationFailed
    case exportCompleted
    case benchmarkCompleted
}

/// Structured event emitted to support UI progress and diagnostics.
public struct BKDiagnosticEvent: Codable, Equatable {
    /// Event creation timestamp.
    public var timestamp: Date
    /// Machine-readable event kind.
    public var kind: BKDiagnosticEventKind
    /// Logical stage label (e.g. `validation`, `parsing`, `simulation`).
    public var stage: String
    /// Human-readable event message.
    public var message: String
    /// Optional structured metadata for UI/debug details.
    public var metadata: [String: String]

    /// Creates a new diagnostics event.
    public init(
        timestamp: Date = Date(),
        kind: BKDiagnosticEventKind,
        stage: String,
        message: String,
        metadata: [String: String] = [:]
    ) {
        self.timestamp = timestamp
        self.kind = kind
        self.stage = stage
        self.message = message
        self.metadata = metadata
    }
}

/// Collects and exposes diagnostics events in FIFO order.
public actor BKDiagnosticsCollector {
    private var events: [BKDiagnosticEvent] = []
    private let maxEvents: Int

    /// Creates a collector with bounded in-memory retention.
    ///
    /// - Parameter maxEvents: Maximum events retained before trimming oldest entries.
    public init(maxEvents: Int = 500) {
        self.maxEvents = max(1, maxEvents)
    }

    /// Appends an event to the collector.
    ///
    /// - Parameter event: Event to store.
    public func append(_ event: BKDiagnosticEvent) {
        events.append(event)
        if events.count > maxEvents {
            events.removeFirst(events.count - maxEvents)
        }
    }

    /// Appends a single structured event built from primitive fields.
    public func emit(
        kind: BKDiagnosticEventKind,
        stage: String,
        message: String,
        metadata: [String: String] = [:]
    ) {
        append(
            BKDiagnosticEvent(
                kind: kind,
                stage: stage,
                message: message,
                metadata: metadata
            )
        )
    }

    /// Returns a snapshot of all retained events.
    public func snapshot() -> [BKDiagnosticEvent] {
        events
    }

    /// Clears all retained events.
    public func clear() {
        events.removeAll(keepingCapacity: true)
    }
}
