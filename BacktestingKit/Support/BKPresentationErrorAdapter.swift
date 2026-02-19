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

    public var uiTitle: String {
        wrapped?.uiTitle ?? "Engine Error"
    }

    public var uiSummary: String {
        wrapped?.uiSummary ?? (base as NSError).localizedDescription
    }

    public var uiDescription: String {
        wrapped?.uiDescription ?? String(describing: base)
    }

    public var uiMetadata: [String: String] {
        var metadata = wrapped?.uiMetadata ?? [:]
        let nsError = base as NSError
        metadata["domain"] = nsError.domain
        metadata["code"] = String(nsError.code)
        return metadata
    }

    public var uiErrorCode: String {
        wrapped?.uiErrorCode ?? "unknown_error"
    }

    public var uiRetryable: Bool {
        wrapped?.uiRetryable ?? false
    }
}
