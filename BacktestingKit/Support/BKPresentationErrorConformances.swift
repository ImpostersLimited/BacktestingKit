import Foundation

/// UI presentation mapping for top-level engine failures.
extension BKEngineFailure: BKUserPresentableError {
    public var uiTitle: String { "Simulation Error" }
    public var uiSummary: String { message }
    public var uiDescription: String {
        var parts: [String] = []
        parts.append("[\(code.rawValue)] stage=\(stage)")
        parts.append(message)
        if let recoverySuggestion, !recoverySuggestion.isEmpty {
            parts.append("Recovery: \(recoverySuggestion)")
        }
        return parts.joined(separator: " | ")
    }
    public var uiMetadata: [String: String] {
        var base: [String: String] = [
            "instrumentID": instrumentID,
            "code": code.rawValue,
            "stage": stage,
            "timestamp": timestamp.ISO8601Format(),
            "retryable": isRetryable ? "true" : "false",
        ]
        for (key, value) in metadata {
            base["meta.\(key)"] = value
        }
        return base
    }
    public var uiErrorCode: String { code.rawValue }
    public var uiRetryable: Bool { isRetryable }
}

/// UI presentation mapping for CSV parsing failures.
extension BKCSVParsingError: BKUserPresentableError {
    public var uiTitle: String { "CSV Parsing Error" }
    public var uiSummary: String { errorDescription ?? String(describing: self) }
    public var uiDescription: String { uiSummary }
    public var uiMetadata: [String: String] {
        ["kind": String(describing: self)]
    }
    public var uiErrorCode: String {
        switch self {
        case .missingHeader: return "missing_header"
        case .missingRequiredColumn: return "missing_required_column"
        case .invalidDate: return "invalid_date"
        case .invalidISO8601Date: return "invalid_iso8601_date"
        case .malformedRow: return "malformed_row"
        case .invalidNumeric: return "invalid_numeric"
        case .nonChronologicalDate: return "non_chronological_date"
        }
    }
}

/// UI presentation mapping for AlphaVantage provider failures.
extension AlphaVantageClientError: BKUserPresentableError {
    public var uiTitle: String { "Data Provider Error" }
    public var uiSummary: String { errorDescription ?? String(describing: self) }
    public var uiDescription: String { uiSummary }
    public var uiMetadata: [String: String] { ["provider": "alphavantage"] }
    public var uiErrorCode: String {
        switch self {
        case .invalidTicker: return "invalid_ticker"
        case .invalidURL: return "invalid_url"
        case .invalidHTTPResponse: return "invalid_http_response"
        case .badStatusCode: return "bad_status_code"
        case .cannotDecodeCSV: return "cannot_decode_csv"
        case .throttled: return "throttled"
        case .apiError: return "api_error"
        case .emptyResponse: return "empty_response"
        }
    }
    public var uiRetryable: Bool {
        switch self {
        case .throttled, .badStatusCode:
            return true
        default:
            return false
        }
    }
}

/// UI presentation mapping for quick demo failures.
extension BKQuickDemoError: BKUserPresentableError {
    public var uiTitle: String { "Demo Error" }
    public var uiSummary: String { errorDescription ?? String(describing: self) }
    public var uiDescription: String { uiSummary }
    public var uiMetadata: [String: String] { ["surface": "quick_demo"] }
    public var uiErrorCode: String {
        switch self {
        case .missingBundledCSV: return "missing_bundled_csv"
        case .emptyCSV: return "empty_csv"
        }
    }
}

/// UI presentation mapping for simulation input/runtime validation failures.
extension BKSimulationDriverError: BKUserPresentableError {
    public var uiTitle: String { "Simulation Input Error" }
    public var uiSummary: String { errorDescription ?? String(describing: self) }
    public var uiDescription: String { uiSummary }
    public var uiMetadata: [String: String] { ["source": "driver"] }
    public var uiErrorCode: String {
        switch self {
        case .emptyInstrumentID: return "empty_instrument_id"
        case .emptyBars: return "empty_bars"
        case .invalidConcurrency: return "invalid_concurrency"
        }
    }
}
