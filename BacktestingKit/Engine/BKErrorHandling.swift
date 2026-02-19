import Foundation

/// Canonical typed failure mapper for public engine APIs.
public enum BKErrorMapper {
    /// Maps any thrown `Error` into a typed `BKEngineFailure`.
    ///
    /// - Parameters:
    ///   - instrumentID: Instrument identifier for contextual reporting.
    ///   - error: Source error.
    /// - Returns: Typed engine failure payload suitable for UI handling.
    public static func map(instrumentID: String, error: Error) -> BKEngineFailure {
        if error is CancellationError {
            return BKEngineFailure(
                instrumentID: instrumentID,
                code: .simulation,
                stage: "cancelled",
                message: "Simulation was cancelled.",
                isRetryable: true,
                recoverySuggestion: "Retry when the app is active or with fewer concurrent jobs."
            )
        }

        if let urlError = error as? URLError {
            return BKEngineFailure(
                instrumentID: instrumentID,
                code: .network,
                stage: "data-fetch",
                message: urlError.localizedDescription,
                isRetryable: true,
                metadata: [
                    "urlErrorCode": String(urlError.errorCode),
                    "urlErrorDomain": URLError.errorDomain,
                ],
                recoverySuggestion: "Check internet connectivity and retry."
            )
        }

        if let alphaVantageError = error as? AlphaVantageClientError {
            let info = classifyAlphaVantageError(alphaVantageError)
            return BKEngineFailure(
                instrumentID: instrumentID,
                code: info.code,
                stage: info.stage,
                message: alphaVantageError.localizedDescription,
                isRetryable: info.isRetryable,
                recoverySuggestion: "Retry with backoff or verify API key/rate limits."
            )
        }

        if let csvError = error as? BKCSVParsingError {
            return BKEngineFailure(
                instrumentID: instrumentID,
                code: .dataParsing,
                stage: "csv-parse",
                message: csvError.localizedDescription,
                isRetryable: false,
                recoverySuggestion: "Verify CSV schema and date format."
            )
        }

        if let driverError = error as? BKSimulationDriverError {
            return BKEngineFailure(
                instrumentID: instrumentID,
                code: .invalidInput,
                stage: "simulation-input",
                message: driverError.localizedDescription,
                isRetryable: false,
                recoverySuggestion: "Validate instrument identifiers and source data coverage."
            )
        }

        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain {
            return BKEngineFailure(
                instrumentID: instrumentID,
                code: .datastore,
                stage: "data-store",
                message: nsError.localizedDescription,
                isRetryable: false,
                metadata: [
                    "nsErrorDomain": nsError.domain,
                    "nsErrorCode": String(nsError.code),
                ],
                recoverySuggestion: "Check local persistence layer state and permissions."
            )
        }

        return BKEngineFailure(
            instrumentID: instrumentID,
            code: .unknown,
            stage: "simulation-run",
            message: String(describing: error),
            isRetryable: false,
            metadata: [
                "nsErrorDomain": nsError.domain,
                "nsErrorCode": String(nsError.code),
            ],
            recoverySuggestion: "Inspect logs and re-run with lower concurrency."
        )
    }

    private static func classifyAlphaVantageError(_ error: AlphaVantageClientError) -> (code: BKEngineErrorCode, stage: String, isRetryable: Bool) {
        switch error {
        case .invalidTicker, .invalidURL:
            return (.invalidInput, "data-fetch", false)
        case .cannotDecodeCSV:
            return (.dataParsing, "csv-parse", false)
        case .invalidHTTPResponse, .badStatusCode, .throttled, .emptyResponse:
            return (.network, "data-fetch", true)
        case .apiError:
            return (.network, "data-fetch", false)
        }
    }
}
