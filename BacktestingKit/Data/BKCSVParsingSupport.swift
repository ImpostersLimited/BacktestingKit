import Foundation

private let atISO8601FullDateFormatterCacheKey = "BacktestingKit.ISO8601.FullDateFormatter"
private let atISO8601InternetDateTimeFormatterCacheKey = "BacktestingKit.ISO8601.InternetDateTimeFormatter"
private let atISO8601InternetDateTimeFractionalFormatterCacheKey = "BacktestingKit.ISO8601.InternetDateTimeFractionalFormatter"

private func atThreadISO8601Formatter(key: String, options: ISO8601DateFormatter.Options) -> ISO8601DateFormatter {
    let dictionary = Thread.current.threadDictionary
    if let formatter = dictionary[key] as? ISO8601DateFormatter {
        return formatter
    }
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.formatOptions = options
    dictionary[key] = formatter
    return formatter
}

func atParseISO8601Date(_ value: String) -> Date? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    let fullDate = atThreadISO8601Formatter(
        key: atISO8601FullDateFormatterCacheKey,
        options: [.withFullDate]
    )
    if let date = fullDate.date(from: trimmed) {
        return date
    }

    let internetDateTime = atThreadISO8601Formatter(
        key: atISO8601InternetDateTimeFormatterCacheKey,
        options: [.withInternetDateTime]
    )
    if let date = internetDateTime.date(from: trimmed) {
        return date
    }

    let internetDateTimeFractional = atThreadISO8601Formatter(
        key: atISO8601InternetDateTimeFractionalFormatterCacheKey,
        options: [.withInternetDateTime, .withFractionalSeconds]
    )
    return internetDateTimeFractional.date(from: trimmed)
}

/// Represents `AlphaVantageClientError` in the BacktestingKit public API.
public enum AlphaVantageClientError: LocalizedError, Equatable {
    case invalidTicker
    case invalidURL
    case invalidHTTPResponse
    case badStatusCode(Int)
    case cannotDecodeCSV
    case throttled(String)
    case apiError(String)
    case emptyResponse

    public var errorDescription: String? {
        switch self {
        case .invalidTicker:
            return "Ticker must not be empty."
        case .invalidURL:
            return "Failed to construct AlphaVantage URL."
        case .invalidHTTPResponse:
            return "Unexpected HTTP response from AlphaVantage."
        case .badStatusCode(let code):
            return "AlphaVantage returned HTTP status \(code)."
        case .cannotDecodeCSV:
            return "Failed to decode CSV payload from AlphaVantage."
        case .throttled(let message):
            return "AlphaVantage throttled the request: \(message)"
        case .apiError(let message):
            return "AlphaVantage returned an API error: \(message)"
        case .emptyResponse:
            return "AlphaVantage returned an empty response."
        }
    }
}

/// Represents `BKCSVParsingError` in the BacktestingKit public API.
public enum BKCSVParsingError: LocalizedError, Equatable {
    case missingHeader
    case missingRequiredColumn(String)
    case invalidDate(String)
    case invalidISO8601Date(value: String, line: Int)
    case malformedRow(line: Int)
    case invalidNumeric(value: String, line: Int)
    case nonChronologicalDate(previous: String, current: String, line: Int)

    public var errorDescription: String? {
        switch self {
        case .missingHeader:
            return "CSV data is missing a header row."
        case .missingRequiredColumn(let column):
            return "CSV data is missing required column '\(column)'."
        case .invalidDate(let value):
            return "Failed to parse date value '\(value)'."
        case .invalidISO8601Date(let value, let line):
            return "Line \(line): expected ISO8601 date string but got '\(value)'."
        case .malformedRow(let line):
            return "Line \(line): malformed CSV row."
        case .invalidNumeric(let value, let line):
            return "Line \(line): failed to parse numeric value '\(value)'."
        case .nonChronologicalDate(let previous, let current, let line):
            return "Line \(line): CSV must be chronological. Previous date '\(previous)', current date '\(current)'."
        }
    }
}

/// Represents `BKCSVColumnMapping` in the BacktestingKit public API.
public struct BKCSVColumnMapping: Equatable, Codable, Sendable {
    public var date: String
    public var open: String
    public var high: String
    public var low: String
    public var close: String
    public var adjustedClose: String?
    public var volume: String

    /// Creates a new instance.
    public init(
        date: String,
        open: String,
        high: String,
        low: String,
        close: String,
        adjustedClose: String? = nil,
        volume: String
    ) {
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.adjustedClose = adjustedClose
        self.volume = volume
    }
}

func atNormalizedColumnKey(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

func atResolveCSVColumnIndices(
    indexMap: [String: Int],
    columnMapping: BKCSVColumnMapping?,
    strict: Bool
) -> Result<(
    dateKey: Int,
    openKey: Int,
    highKey: Int,
    lowKey: Int,
    closeKey: Int,
    adjustedCloseKey: Int?,
    volumeKey: Int
) , BKCSVParsingError> {
    if let columnMapping {
        func mappedColumn(_ rawName: String) -> Result<Int, BKCSVParsingError> {
            let name = atNormalizedColumnKey(rawName)
            guard let index = indexMap[name] else {
                return .failure(BKCSVParsingError.missingRequiredColumn(rawName))
            }
            return .success(index)
        }

        guard case .success(let dateKey) = mappedColumn(columnMapping.date) else {
            return .failure(.missingRequiredColumn(columnMapping.date))
        }
        guard case .success(let openKey) = mappedColumn(columnMapping.open) else {
            return .failure(.missingRequiredColumn(columnMapping.open))
        }
        guard case .success(let highKey) = mappedColumn(columnMapping.high) else {
            return .failure(.missingRequiredColumn(columnMapping.high))
        }
        guard case .success(let lowKey) = mappedColumn(columnMapping.low) else {
            return .failure(.missingRequiredColumn(columnMapping.low))
        }
        guard case .success(let closeKey) = mappedColumn(columnMapping.close) else {
            return .failure(.missingRequiredColumn(columnMapping.close))
        }
        let adjustedCloseKey: Int?
        if let adjustedCloseName = columnMapping.adjustedClose {
            switch mappedColumn(adjustedCloseName) {
            case .success(let key):
                adjustedCloseKey = key
            case .failure(let error):
                return .failure(error)
            }
        } else {
            adjustedCloseKey = nil
        }
        guard case .success(let volumeKey) = mappedColumn(columnMapping.volume) else {
            return .failure(.missingRequiredColumn(columnMapping.volume))
        }

        return .success((
            dateKey: dateKey,
            openKey: openKey,
            highKey: highKey,
            lowKey: lowKey,
            closeKey: closeKey,
            adjustedCloseKey: adjustedCloseKey,
            volumeKey: volumeKey
        ))
    }

    func requireColumn(_ name: String, fallback: Int?) -> Result<Int, BKCSVParsingError> {
        if let value = indexMap[name] {
            return .success(value)
        }
        if let fallback {
            return .success(fallback)
        }
        return .failure(BKCSVParsingError.missingRequiredColumn(name))
    }

    func optionalColumn(_ names: [String]) -> Int? {
        for name in names {
            if let index = indexMap[name] {
                return index
            }
        }
        return nil
    }

    guard case .success(let dateKey) = requireColumn("timestamp", fallback: indexMap["time"] ?? indexMap["date"] ?? (strict ? nil : 0)) else {
        return .failure(.missingRequiredColumn("timestamp"))
    }
    guard case .success(let openKey) = requireColumn("open", fallback: strict ? nil : 1) else {
        return .failure(.missingRequiredColumn("open"))
    }
    guard case .success(let highKey) = requireColumn("high", fallback: strict ? nil : 2) else {
        return .failure(.missingRequiredColumn("high"))
    }
    guard case .success(let lowKey) = requireColumn("low", fallback: strict ? nil : 3) else {
        return .failure(.missingRequiredColumn("low"))
    }
    guard case .success(let closeKey) = requireColumn("close", fallback: strict ? nil : 4) else {
        return .failure(.missingRequiredColumn("close"))
    }
    guard case .success(let volumeKey) = requireColumn("volume", fallback: strict ? nil : 5) else {
        return .failure(.missingRequiredColumn("volume"))
    }

    return .success((
        dateKey: dateKey,
        openKey: openKey,
        highKey: highKey,
        lowKey: lowKey,
        closeKey: closeKey,
        adjustedCloseKey: optionalColumn(["adjusted_close", "adj_close", "adjclose", "adjusted close"]),
        volumeKey: volumeKey
    ))
}

/// Represents `AlphaVantageRetryPolicy` in the BacktestingKit public API.
