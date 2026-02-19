import Foundation

/// UI-facing presentation contract for success and error payloads.
///
/// Use this protocol to expose human-readable, stable summaries that can be rendered
/// directly in app surfaces without reverse-engineering internal model fields.
public protocol BKUserPresentablePayload {
    /// Short user-facing title suitable for list rows and banners.
    var uiTitle: String { get }
    /// One-line summary focused on the most important outcome.
    var uiSummary: String { get }
    /// Verbose explanatory description for detail views/log panes.
    var uiDescription: String { get }
    /// Structured key-value data that UI can render in tables or chips.
    var uiMetadata: [String: String] { get }
}

public extension BKUserPresentablePayload {
    var uiTitle: String { String(describing: Self.self) }
    var uiSummary: String { String(describing: self) }
    var uiDescription: String { uiSummary }
    var uiMetadata: [String: String] { [:] }
}

/// Specialization for error payloads.
///
/// This protocol is intended for engine/domain errors that should be rendered
/// directly in UI while preserving machine-usable classification metadata.
public protocol BKUserPresentableError: BKUserPresentablePayload, Error {
    /// Stable error code string suitable for analytics and conditional UI handling.
    var uiErrorCode: String { get }
    /// Whether the failure is likely recoverable by retrying.
    var uiRetryable: Bool { get }
}

public extension BKUserPresentableError {
    var uiErrorCode: String { String(describing: Self.self) }
    var uiRetryable: Bool { false }
}

/// Generic Result presenter for UI consumers.
///
/// `BKResultPresentation` is a normalized envelope that allows UI layers to
/// consume success/error results consistently without type-switching on domain models.
public struct BKResultPresentation: Equatable, Codable {
    /// User-facing title.
    public let title: String
    /// Short user-facing summary.
    public let summary: String
    /// Verbose, diagnostics-friendly description.
    public let description: String
    /// Structured key-value metadata for chips/rows/detail panes.
    public let metadata: [String: String]
    /// `true` when this represents a failure payload.
    public let isError: Bool
    /// Optional machine-readable error code for failures.
    public let errorCode: String?
    /// Optional retryability hint for failures.
    public let isRetryable: Bool?

    /// Creates a new instance.
    public init(
        title: String,
        summary: String,
        description: String,
        metadata: [String: String],
        isError: Bool,
        errorCode: String? = nil,
        isRetryable: Bool? = nil
    ) {
        self.title = title
        self.summary = summary
        self.description = description
        self.metadata = metadata
        self.isError = isError
        self.errorCode = errorCode
        self.isRetryable = isRetryable
    }
}

public extension Result where Success: BKUserPresentablePayload, Failure: BKUserPresentableError {
    /// Converts a typed result into a UI-normalized presentation envelope.
    ///
    /// This is useful for SwiftUI/UIKIt layers that want to render a common
    /// success/error view model without coupling to concrete domain types.
    var uiPresentation: BKResultPresentation {
        switch self {
        case .success(let payload):
            return BKResultPresentation(
                title: payload.uiTitle,
                summary: payload.uiSummary,
                description: payload.uiDescription,
                metadata: payload.uiMetadata,
                isError: false
            )
        case .failure(let failure):
            return BKResultPresentation(
                title: failure.uiTitle,
                summary: failure.uiSummary,
                description: failure.uiDescription,
                metadata: failure.uiMetadata,
                isError: true,
                errorCode: failure.uiErrorCode,
                isRetryable: failure.uiRetryable
            )
        }
    }
}
