import Foundation

/// Adapts an arbitrary `Error` into a `BKUserPresentableError` for UI consumption.
public struct BKAnyPresentationError: BKUserPresentableError {
    private let base: Error
    private let wrapped: BKUserPresentableError?

    /// Creates a new instance.
    public init(_ base: Error) {
        self.base = base
        self.wrapped = base as? BKUserPresentableError
    }

    /// Short title used when presenting this value to people.
    public var uiTitle: String {
        wrapped?.uiTitle ?? "Engine Error"
    }

    /// One-line summary used when presenting this value to people.
    public var uiSummary: String {
        wrapped?.uiSummary ?? (base as NSError).localizedDescription
    }

    /// Detailed description used when presenting this value to people.
    public var uiDescription: String {
        wrapped?.uiDescription ?? String(describing: base)
    }

    /// Structured metadata associated with this value.
    public var uiMetadata: [String: String] {
        var metadata = wrapped?.uiMetadata ?? [:]
        let nsError = base as NSError
        metadata["domain"] = nsError.domain
        metadata["code"] = String(nsError.code)
        return metadata
    }

    /// Stable error code used for presentation and diagnostics.
    public var uiErrorCode: String {
        wrapped?.uiErrorCode ?? "unknown_error"
    }

    /// Whether the operation can be retried safely.
    public var uiRetryable: Bool {
        wrapped?.uiRetryable ?? false
    }
}
