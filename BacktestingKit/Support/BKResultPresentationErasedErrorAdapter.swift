import Foundation

public extension Result where Success: BKUserPresentablePayload, Failure == Error {
    /// Produces a unified UI presentation for APIs that intentionally erase failure type to `Error`.
    var uiPresentation: BKResultPresentation {
        switch self {
        case .success(let success):
            return BKResultPresentation(
                title: success.uiTitle,
                summary: success.uiSummary,
                description: success.uiDescription,
                metadata: success.uiMetadata,
                isError: false
            )
        case .failure(let error):
            let adapted = BKAnyPresentationError(error)
            return BKResultPresentation(
                title: adapted.uiTitle,
                summary: adapted.uiSummary,
                description: adapted.uiDescription,
                metadata: adapted.uiMetadata,
                isError: true,
                errorCode: adapted.uiErrorCode,
                isRetryable: adapted.uiRetryable
            )
        }
    }
}
