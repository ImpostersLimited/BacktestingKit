import Foundation

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

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func getRawCsv(ticker: String, p1: Double = 0, p2: Double = 0) async throws -> String {
        var components = URLComponents(string: "https://www.alphavantage.co/query")!
        components.queryItems = [
            URLQueryItem(name: "function", value: "TIME_SERIES_DAILY_ADJUSTED"),
            URLQueryItem(name: "symbol", value: ticker),
            URLQueryItem(name: "outputsize", value: "full"),
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "datatype", value: "csv"),
            URLQueryItem(name: "entitlement", value: "delayed"),
        ]
        let request = URLRequest(url: components.url!)
        let (data, _) = try await session.data(for: request)
        guard let csv = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        return csv
    }

    public func getInstrumentDetail(ticker: String) async throws -> ATV3_InstrumentDetail {
        var components = URLComponents(string: "https://www.alphavantage.co/query")!
        components.queryItems = [
            URLQueryItem(name: "function", value: "OVERVIEW"),
            URLQueryItem(name: "symbol", value: ticker),
            URLQueryItem(name: "apikey", value: apiKey),
        ]
        let request = URLRequest(url: components.url!)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(ATV3_InstrumentDetail.self, from: data)
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
