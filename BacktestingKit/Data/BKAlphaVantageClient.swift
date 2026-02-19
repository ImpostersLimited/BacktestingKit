import Foundation

public struct AlphaVantageClient: BKRawCsvProvider {
    public var apiKey: String
    public var session: URLSession
    public var retryPolicy: AlphaVantageRetryPolicy
    public var rateLimiter: BKRequestRateLimiter?

    /// Creates a new instance.
    public init(
        apiKey: String,
        session: URLSession = .shared,
        retryPolicy: AlphaVantageRetryPolicy = AlphaVantageRetryPolicy(),
        rateLimiter: BKRequestRateLimiter? = nil
    ) {
        self.apiKey = apiKey
        self.session = session
        self.retryPolicy = retryPolicy
        self.rateLimiter = rateLimiter
    }

    /// Executes `getRawCsv`.
    public func getRawCsv(ticker: String, p1: Double = 0, p2: Double = 0) async -> Result<String, Error> {
        let normalizedTicker = ticker.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTicker.isEmpty else {
            return .failure(AlphaVantageClientError.invalidTicker)
        }
        guard var components = URLComponents(string: "https://www.alphavantage.co/query") else {
            return .failure(AlphaVantageClientError.invalidURL)
        }
        components.queryItems = [
            URLQueryItem(name: "function", value: "TIME_SERIES_DAILY_ADJUSTED"),
            URLQueryItem(name: "symbol", value: normalizedTicker),
            URLQueryItem(name: "outputsize", value: "full"),
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "datatype", value: "csv"),
            URLQueryItem(name: "entitlement", value: "delayed"),
        ]
        guard let url = components.url else {
            return .failure(AlphaVantageClientError.invalidURL)
        }
        let request = URLRequest(url: url)
        let data: Data
        switch await requestDataWithRetry(request) {
        case .success(let resolvedData):
            data = resolvedData
        case .failure(let error):
            return .failure(error)
        }
        guard let payload = String(data: data, encoding: .utf8) else {
            return .failure(AlphaVantageClientError.cannotDecodeCSV)
        }
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(AlphaVantageClientError.emptyResponse)
        }
        if let apiError = detectAlphaVantageError(from: trimmed) {
            return .failure(apiError)
        }
        return .success(payload)
    }

    /// Executes `getInstrumentDetail`.
    public func getInstrumentDetail(ticker: String) async -> Result<BKV3_InstrumentDetail, Error> {
        let normalizedTicker = ticker.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTicker.isEmpty else {
            return .failure(AlphaVantageClientError.invalidTicker)
        }
        guard var components = URLComponents(string: "https://www.alphavantage.co/query") else {
            return .failure(AlphaVantageClientError.invalidURL)
        }
        components.queryItems = [
            URLQueryItem(name: "function", value: "OVERVIEW"),
            URLQueryItem(name: "symbol", value: normalizedTicker),
            URLQueryItem(name: "apikey", value: apiKey),
        ]
        guard let url = components.url else {
            return .failure(AlphaVantageClientError.invalidURL)
        }
        let request = URLRequest(url: url)
        let data: Data
        switch await requestDataWithRetry(request) {
        case .success(let resolvedData):
            data = resolvedData
        case .failure(let error):
            return .failure(error)
        }
        if let text = String(data: data, encoding: .utf8),
           let apiError = detectAlphaVantageError(from: text) {
            return .failure(apiError)
        }
        do {
            return .success(try JSONDecoder().decode(BKV3_InstrumentDetail.self, from: data))
        } catch {
            return .failure(error)
        }
    }

    private func requestDataWithRetry(_ request: URLRequest) async -> Result<Data, Error> {
        var attempt = 1
        var currentBackoff = retryPolicy.initialBackoffSeconds
        var lastError: Error?

        while attempt <= retryPolicy.maxAttempts {
            do {
                if let limiter = rateLimiter,
                   case .failure(let limiterError) = await limiter.acquire() {
                    return .failure(limiterError)
                }
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw AlphaVantageClientError.invalidHTTPResponse
                }
                guard (200..<300).contains(http.statusCode) else {
                    throw AlphaVantageClientError.badStatusCode(http.statusCode)
                }
                return .success(data)
            } catch {
                lastError = error
                let isLastAttempt = attempt == retryPolicy.maxAttempts
                if isLastAttempt {
                    break
                }
                do {
                    try await Task.sleep(for: .seconds(currentBackoff))
                } catch {
                    return .failure(error)
                }
                currentBackoff *= 2
                attempt += 1
            }
        }

        return .failure(lastError ?? AlphaVantageClientError.emptyResponse)
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

/// Executes `csvToBars`.
