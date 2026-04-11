import Foundation

/// Represents `BKQuickDemoDataset` in the BacktestingKit public API.
public enum BKQuickDemoDataset: String, CaseIterable, Sendable {
    case aapl = "AAPL_10Y_1D"
    case msft = "MSFT_10Y_1D"
    case googl = "GOOGL_10Y_1D"
    case nvda = "NVDA_10Y_1D"
    case tsla = "TSLA_10Y_1D"
    case amzn = "AMZN_10Y_1D"
    case jpm = "JPM_10Y_1D"
    case xom = "XOM_10Y_1D"
    case wmt = "WMT_10Y_1D"
    case ko = "KO_10Y_1D"

    public var symbol: String {
        switch self {
        case .aapl: return "AAPL"
        case .msft: return "MSFT"
        case .googl: return "GOOGL"
        case .nvda: return "NVDA"
        case .tsla: return "TSLA"
        case .amzn: return "AMZN"
        case .jpm: return "JPM"
        case .xom: return "XOM"
        case .wmt: return "WMT"
        case .ko: return "KO"
        }
    }

    public var exchange: String {
        switch self {
        case .aapl, .msft, .googl, .nvda, .tsla, .amzn:
            return "NASDAQ"
        case .jpm, .xom, .wmt, .ko:
            return "NYSE"
        }
    }
}

/// Represents `BKQuickDemoError` in the BacktestingKit public API.
public enum BKQuickDemoError: LocalizedError {
    case missingBundledCSV(BKQuickDemoDataset)
    case emptyCSV
    case unsupportedPreset(BKPresetCatalog)

    public var errorDescription: String? {
        switch self {
        case .missingBundledCSV(let dataset):
            return "Bundled demo CSV '\(dataset.rawValue).csv' is missing. Reinstall the package and try again."
        case .emptyCSV:
            return "Demo CSV was parsed but no bars were produced."
        case .unsupportedPreset(let preset):
            return "Preset '\(preset.displayName)' is not supported by the bundled quick demo helpers."
        }
    }
}

/// Represents `BKQuickDemoSummary` in the BacktestingKit public API.
public struct BKQuickDemoSummary {
    public let symbol: String
    public let barCount: Int
    public let dateRangeStart: Date
    public let dateRangeEnd: Date
    public let result: BacktestResult

    /// Creates a new instance.
    public init(
        symbol: String,
        barCount: Int,
        dateRangeStart: Date,
        dateRangeEnd: Date,
        result: BacktestResult
    ) {
        self.symbol = symbol
        self.barCount = barCount
        self.dateRangeStart = dateRangeStart
        self.dateRangeEnd = dateRangeEnd
        self.result = result
    }
}

/// Represents `BKQuickDemo` in the BacktestingKit public API.
public enum BKQuickDemo {
    private final class BundleToken {}

    private static func bundledCSVURL(for dataset: BKQuickDemoDataset) -> URL? {
        #if SWIFT_PACKAGE
        return Bundle.module.url(forResource: dataset.rawValue, withExtension: "csv")
        #else
        let frameworkBundle = Bundle(for: BundleToken.self)
        if let url = frameworkBundle.url(forResource: dataset.rawValue, withExtension: "csv") {
            return url
        }
        return Bundle.main.url(forResource: dataset.rawValue, withExtension: "csv")
        #endif
    }

    /// Loads bundled CSV text for a demo dataset.
    public static func loadBundledCSV(dataset: BKQuickDemoDataset) -> Result<String, Error> {
        guard let csvURL = bundledCSVURL(for: dataset) else {
            return .failure(BKQuickDemoError.missingBundledCSV(dataset))
        }

        do {
            return .success(try String(contentsOf: csvURL, encoding: .utf8))
        } catch {
            return .failure(error)
        }
    }

    /// Parses CSV into chronological bars for quick-demo workflows.
    public static func parseBars(
        csv: String,
        dateFormat: String = "yyyy-MM-dd",
        reverse: Bool = false,
        columnMapping: BKCSVColumnMapping? = nil
    ) -> Result<[BKBar], Error> {
        let trimmed = csv.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(BKQuickDemoError.emptyCSV)
        }

        switch csvToBars(trimmed, dateFormat: dateFormat, reverse: reverse, columnMapping: columnMapping) {
        case .success(let bars):
            guard !bars.isEmpty else {
                return .failure(BKQuickDemoError.emptyCSV)
            }
            return .success(bars)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Converts parsed bars into candles for manager-driven workflows.
    public static func makeCandles(from bars: [BKBar]) -> [Candlestick] {
        bars.map {
            Candlestick(
                date: $0.time,
                open: $0.open,
                high: $0.high,
                low: $0.low,
                close: $0.close,
                volume: $0.volume
            )
        }
    }

    /// Builds an onboarding-friendly run summary from demo inputs.
    public static func summarize(
        symbol: String,
        bars: [BKBar],
        result: BacktestResult
    ) -> BKRunSummary {
        BKEngine.summarize(symbol: symbol, bars: bars, result: result)
    }

    /// One-line quick demo for Playground/SPM users.
    /// Runs bundled 10y/1d SMA crossover (5/20) from bundled CSV (offline).
    @discardableResult
    public static func runBundledSMACrossoverDemo(
        dataset: BKQuickDemoDataset = .aapl,
        csv: String? = nil,
        log: @Sendable (String) -> Void = { print($0) }
    ) -> Result<BKQuickDemoSummary, Error> {
        let startedAt = Date()
        log("[Demo] Starting quick trial demo (offline).")
        log("[Demo] Strategy: SMA crossover (5 / 20), Symbol: \(dataset.symbol), Exchange: \(dataset.exchange), Interval: 1d, Span: ~10y.")

        let csvData: String
        if let csv {
            csvData = csv
            log("[Demo] Using caller-provided CSV input.")
        } else {
            log("[Demo] Loading bundled sample CSV (\(dataset.rawValue).csv)...")
            switch loadBundledCSV(dataset: dataset) {
            case .success(let bundledCSV):
                csvData = bundledCSV
            case .failure(let error):
                return .failure(error)
            }
        }

        log("[Demo] Parsing CSV with strict chronological + ISO8601-compatible date handling...")
        let bars: [BKBar]
        switch parseBars(csv: csvData, dateFormat: "yyyy-MM-dd", reverse: false) {
        case .success(let parsed):
            bars = parsed
        case .failure(let error):
            return .failure(error)
        }
        log("[Demo] Parsed \(bars.count) bars.")

        let candles = makeCandles(from: bars)

        log("[Demo] Running backtest...")
        let manager = BacktestingKitManager()
        let result = manager.backtestSMACrossover(candles: candles, fast: 5, slow: 20)

        let percentStyle = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(2))
        let ratioStyle = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(4))
        let start = bars[0].time
        let end = bars[bars.count - 1].time
        log("[Demo] Date range: \(start.ISO8601Format()) -> \(end.ISO8601Format())")
        log("[Demo] Trades: \(result.numTrades) (wins: \(result.numWins), losses: \(result.numLosses))")
        log("[Demo] Win rate: \((result.winRate * 100.0).formatted(percentStyle))%")
        log("[Demo] Total return: \((result.totalReturn * 100.0).formatted(percentStyle))%")
        log("[Demo] Annualized return: \((result.annualizedReturn * 100.0).formatted(percentStyle))%")
        log("[Demo] Max drawdown: \((result.maxDrawdown * 100.0).formatted(percentStyle))%")
        log("[Demo] Sharpe ratio: \(result.sharpeRatio.formatted(ratioStyle))")
        log("[Demo] Profit factor: \(result.profitFactor.formatted(ratioStyle))")

        let elapsed = Date().timeIntervalSince(startedAt)
        log("[Demo] Completed in \(elapsed.formatted(.number.precision(.fractionLength(2))))s.")

        return .success(BKQuickDemoSummary(
            symbol: dataset.symbol,
            barCount: bars.count,
            dateRangeStart: start,
            dateRangeEnd: end,
            result: result
        ))
    }

    /// Runs an SMA crossover workflow directly from inline CSV.
    @discardableResult
    public static func runSMACrossoverDemo(
        symbol: String,
        csv: String,
        fast: Int = 5,
        slow: Int = 20,
        log: @Sendable (String) -> Void = { print($0) }
    ) -> Result<BKQuickDemoSummary, Error> {
        let trimmed = csv.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(BKQuickDemoError.emptyCSV)
        }

        log("[Demo] Starting inline CSV SMA crossover demo.")
        log("[Demo] Strategy: SMA crossover (\(fast) / \(slow)), Symbol: \(symbol).")

        let bars: [BKBar]
        switch parseBars(csv: csv, dateFormat: "yyyy-MM-dd", reverse: false) {
        case .success(let parsed):
            bars = parsed
        case .failure(let error):
            return .failure(error)
        }
        let candles = makeCandles(from: bars)

        let manager = BacktestingKitManager()
        let result = manager.backtestSMACrossover(candles: candles, fast: fast, slow: slow)
        return .success(
            BKQuickDemoSummary(
                symbol: symbol,
                barCount: bars.count,
                dateRangeStart: bars[0].time,
                dateRangeEnd: bars[bars.count - 1].time,
                result: result
            )
        )
    }

    @discardableResult
    public static func runAAPL10Y1DSMACrossover(
        csv: String? = nil,
        log: @Sendable (String) -> Void = { print($0) }
    ) -> Result<BKQuickDemoSummary, Error> {
        runBundledSMACrossoverDemo(dataset: .aapl, csv: csv, log: log)
    }
}

/// Provides the `BKDemoDataset` typealias for BacktestingKit interoperability.
public typealias BKDemoDataset = BKQuickDemoDataset
