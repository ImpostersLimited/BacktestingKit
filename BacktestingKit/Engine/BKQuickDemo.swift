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

    public var errorDescription: String? {
        switch self {
        case .missingBundledCSV(let dataset):
            return "Bundled demo CSV '\(dataset.rawValue).csv' is missing. Reinstall the package and try again."
        case .emptyCSV:
            return "Demo CSV was parsed but no bars were produced."
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
            guard let csvURL = bundledCSVURL(for: dataset) else {
                return .failure(BKQuickDemoError.missingBundledCSV(dataset))
            }
            do {
                csvData = try String(contentsOf: csvURL, encoding: .utf8)
            } catch {
                return .failure(error)
            }
        }

        log("[Demo] Parsing CSV with strict chronological + ISO8601-compatible date handling...")
        let bars: [BKBar]
        switch csvToBars(csvData, dateFormat: "yyyy-MM-dd", reverse: false) {
        case .success(let parsed):
            bars = parsed
        case .failure(let error):
            return .failure(error)
        }
        guard !bars.isEmpty else {
            return .failure(BKQuickDemoError.emptyCSV)
        }
        log("[Demo] Parsed \(bars.count) bars.")

        let candles = bars.map {
            Candlestick(
                date: $0.time,
                open: $0.open,
                high: $0.high,
                low: $0.low,
                close: $0.close,
                volume: $0.volume
            )
        }

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
