import Foundation

/// Severity level for a validation issue.
public enum BKValidationSeverity: String, Codable, Equatable {
    case info
    case warning
    case error
}

/// A single validation finding emitted by `BKValidationTool`.
public struct BKValidationIssue: Codable, Equatable {
    /// Stable issue code suitable for client-side branching.
    public var code: String
    /// Field or input path associated with the issue.
    public var field: String
    /// Human-readable issue description.
    public var message: String
    /// Severity level (`info`, `warning`, `error`).
    public var severity: BKValidationSeverity
    /// Optional key-value context for UI/debug overlays.
    public var metadata: [String: String]

    /// Creates a new validation issue.
    public init(
        code: String,
        field: String,
        message: String,
        severity: BKValidationSeverity,
        metadata: [String: String] = [:]
    ) {
        self.code = code
        self.field = field
        self.message = message
        self.severity = severity
        self.metadata = metadata
    }
}

/// Aggregated output from a validation run.
public struct BKValidationReport: Codable, Equatable {
    /// True when no error-severity issues are present.
    public var isValid: Bool
    /// Ordered issue list collected during validation.
    public var issues: [BKValidationIssue]

    /// Creates a new validation report.
    public init(isValid: Bool, issues: [BKValidationIssue]) {
        self.isValid = isValid
        self.issues = issues
    }
}

/// Input validation utilities for CSV payloads and one-liner requests.
public enum BKValidationTool {
    /// Validates CSV payload shape and strict parseability.
    ///
    /// - Parameters:
    ///   - csv: Raw CSV text.
    ///   - columnMapping: Optional custom mapping between CSV columns and mandatory OHLCV fields.
    /// - Returns: Structured validation report suitable for UI display.
    public static func validateCSV(
        _ csv: String,
        columnMapping: BKCSVColumnMapping? = nil
    ) -> BKValidationReport {
        let trimmed = csv.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return BKValidationReport(
                isValid: false,
                issues: [
                    BKValidationIssue(
                        code: "csv_empty",
                        field: "csv",
                        message: "CSV input is empty.",
                        severity: .error
                    )
                ]
            )
        }

        switch csvToBarsStreaming(
            csv,
            reverse: false,
            strict: true,
            columnMapping: columnMapping
        ) {
        case .success(let bars):
            if bars.isEmpty {
                return BKValidationReport(
                    isValid: false,
                    issues: [
                        BKValidationIssue(
                            code: "csv_no_rows",
                            field: "csv",
                            message: "CSV parsed but contained no data rows.",
                            severity: .error
                        )
                    ]
                )
            }
            return BKValidationReport(
                isValid: true,
                issues: [
                    BKValidationIssue(
                        code: "csv_ok",
                        field: "csv",
                        message: "CSV is valid (\(bars.count) rows).",
                        severity: .info,
                        metadata: ["rowCount": String(bars.count)]
                    )
                ]
            )
        case .failure(let error):
            return BKValidationReport(
                isValid: false,
                issues: [
                    BKValidationIssue(
                        code: "csv_parse_error",
                        field: "csv",
                        message: error.errorDescription ?? String(describing: error),
                        severity: .error,
                        metadata: ["kind": String(describing: error)]
                    )
                ]
            )
        }
    }

    /// Validates a v2 request shape before execution.
    ///
    /// - Parameter request: One-liner v2 request.
    /// - Returns: Validation report.
    public static func validateV2Request(_ request: BKEngine.V2Request) -> BKValidationReport {
        var issues: [BKValidationIssue] = []
        if request.instrumentID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(
                BKValidationIssue(
                    code: "instrument_id_empty",
                    field: "instrumentID",
                    message: "Instrument ID must not be empty.",
                    severity: .error
                )
            )
        }
        if request.p2 < request.p1 {
            issues.append(
                BKValidationIssue(
                    code: "period_inverted",
                    field: "p1,p2",
                    message: "p2 is earlier than p1; data provider may return unexpected ranges.",
                    severity: .warning
                )
            )
        }
        return BKValidationReport(isValid: !issues.contains(where: { $0.severity == .error }), issues: issues)
    }

    /// Validates a v3 request shape before execution.
    ///
    /// - Parameter request: One-liner v3 request.
    /// - Returns: Validation report.
    public static func validateV3Request(_ request: BKEngine.V3Request) -> BKValidationReport {
        var issues: [BKValidationIssue] = []
        if request.instrument.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(
                BKValidationIssue(
                    code: "instrument_id_empty",
                    field: "instrument.id",
                    message: "Instrument ID must not be empty.",
                    severity: .error
                )
            )
        }
        if request.executionOptions.maxBarsPerInstrument == 0 {
            issues.append(
                BKValidationIssue(
                    code: "max_bars_zero",
                    field: "executionOptions.maxBarsPerInstrument",
                    message: "maxBarsPerInstrument = 0 will return no bars.",
                    severity: .warning
                )
            )
        }
        return BKValidationReport(isValid: !issues.contains(where: { $0.severity == .error }), issues: issues)
    }
}
