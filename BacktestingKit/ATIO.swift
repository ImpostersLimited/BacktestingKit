import Foundation

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

public struct AlphaVantageRetryPolicy: Equatable, Sendable {
    public var maxAttempts: Int
    public var initialBackoffSeconds: Double

    public init(maxAttempts: Int = 3, initialBackoffSeconds: Double = 1.0) {
        self.maxAttempts = max(1, maxAttempts)
        self.initialBackoffSeconds = max(0.1, initialBackoffSeconds)
    }
}

public protocol ATV3DataStore {
    func getConfigs(instrumentID: String) async throws -> [ATV3_Config]
    func getSimulationRules(configID: String, ruleType: String) async throws -> [ATV3_SimulationRule]
    func saveConfig(_ config: ATV3_Config) async throws
    func saveAnalysis(_ analysis: ATV3_AnalysisProfile) async throws
    func saveTrades(_ trades: [ATV3_TradeEntry]) async throws
    func saveSimulationRules(_ rules: [ATV3_SimulationRule]) async throws
    func saveRisks(_ risks: [ATV3_RiskProfile]) async throws
}

public protocol ATRawCsvProvider {
    func getRawCsv(ticker: String, p1: Double, p2: Double) async throws -> String
}

public struct AlphaVantageClient: ATRawCsvProvider {
    public var apiKey: String
    public var session: URLSession
    public var retryPolicy: AlphaVantageRetryPolicy

    public init(
        apiKey: String,
        session: URLSession = .shared,
        retryPolicy: AlphaVantageRetryPolicy = AlphaVantageRetryPolicy()
    ) {
        self.apiKey = apiKey
        self.session = session
        self.retryPolicy = retryPolicy
    }

    public func getRawCsv(ticker: String, p1: Double = 0, p2: Double = 0) async throws -> String {
        let normalizedTicker = ticker.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTicker.isEmpty else {
            throw AlphaVantageClientError.invalidTicker
        }
        var components = URLComponents(string: "https://www.alphavantage.co/query")!
        components.queryItems = [
            URLQueryItem(name: "function", value: "TIME_SERIES_DAILY_ADJUSTED"),
            URLQueryItem(name: "symbol", value: normalizedTicker),
            URLQueryItem(name: "outputsize", value: "full"),
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "datatype", value: "csv"),
            URLQueryItem(name: "entitlement", value: "delayed"),
        ]
        guard let url = components.url else {
            throw AlphaVantageClientError.invalidURL
        }
        let request = URLRequest(url: url)
        let data = try await requestDataWithRetry(request)
        guard let payload = String(data: data, encoding: .utf8) else {
            throw AlphaVantageClientError.cannotDecodeCSV
        }
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AlphaVantageClientError.emptyResponse
        }
        if let apiError = detectAlphaVantageError(from: trimmed) {
            throw apiError
        }
        return payload
    }

    public func getInstrumentDetail(ticker: String) async throws -> ATV3_InstrumentDetail {
        let normalizedTicker = ticker.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTicker.isEmpty else {
            throw AlphaVantageClientError.invalidTicker
        }
        var components = URLComponents(string: "https://www.alphavantage.co/query")!
        components.queryItems = [
            URLQueryItem(name: "function", value: "OVERVIEW"),
            URLQueryItem(name: "symbol", value: normalizedTicker),
            URLQueryItem(name: "apikey", value: apiKey),
        ]
        guard let url = components.url else {
            throw AlphaVantageClientError.invalidURL
        }
        let request = URLRequest(url: url)
        let data = try await requestDataWithRetry(request)
        if let text = String(data: data, encoding: .utf8),
           let apiError = detectAlphaVantageError(from: text) {
            throw apiError
        }
        return try JSONDecoder().decode(ATV3_InstrumentDetail.self, from: data)
    }

    private func requestDataWithRetry(_ request: URLRequest) async throws -> Data {
        var attempt = 1
        var currentBackoff = retryPolicy.initialBackoffSeconds
        var lastError: Error?

        while attempt <= retryPolicy.maxAttempts {
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw AlphaVantageClientError.invalidHTTPResponse
                }
                guard (200..<300).contains(http.statusCode) else {
                    throw AlphaVantageClientError.badStatusCode(http.statusCode)
                }
                return data
            } catch {
                lastError = error
                let isLastAttempt = attempt == retryPolicy.maxAttempts
                if isLastAttempt {
                    break
                }
                try await Task.sleep(nanoseconds: UInt64(currentBackoff * 1_000_000_000))
                currentBackoff *= 2
                attempt += 1
            }
        }

        throw lastError ?? AlphaVantageClientError.emptyResponse
    }

    private func detectAlphaVantageError(from payload: String) -> AlphaVantageClientError? {
        let lowercased = payload.lowercased()
        if lowercased.contains("\"note\"") || lowercased.contains("api call frequency") {
            return .throttled(payload)
        }
        if lowercased.contains("\"error message\"") || lowercased.contains("\"information\"") {
            return .apiError(payload)
        }
        return nil
    }
}

public func csvToBars(
    _ csv: String,
    dateFormat: String = "yyyy-MM-dd",
    reverse: Bool = true
) -> [ATBar] {
    let lines = csv.split(separator: "\n").map { String($0) }
    guard let header = lines.first else { return [] }
    let columns = header.split(separator: ",").map { String($0) }
    let indexMap = Dictionary(uniqueKeysWithValues: columns.enumerated().map { ($1.lowercased(), $0) })
    let dateKey = indexMap["timestamp"] ?? indexMap["time"] ?? indexMap["date"] ?? 0
    let openKey = indexMap["open"] ?? 1
    let highKey = indexMap["high"] ?? 2
    let lowKey = indexMap["low"] ?? 3
    let closeKey = indexMap["close"] ?? 4
    let volumeKey = indexMap["volume"] ?? 5

    let formatter = DateFormatter()
    formatter.dateFormat = dateFormat
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    var bars: [ATBar] = []
    for line in lines.dropFirst() {
        let fields = line.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        guard fields.count > max(volumeKey, closeKey),
              let date = formatter.date(from: fields[dateKey]),
              let open = Double(fields[openKey]),
              let high = Double(fields[highKey]),
              let low = Double(fields[lowKey]),
              let close = Double(fields[closeKey]),
              let volume = Double(fields[volumeKey]) else {
            continue
        }
        bars.append(ATBar(time: date, open: open, high: high, low: low, close: close, volume: volume))
    }

    return reverse ? bars.reversed() : bars
}
