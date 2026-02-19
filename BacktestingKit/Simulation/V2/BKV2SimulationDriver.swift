import Foundation

public final class BKV2SimulationDriver: BKV2SimulationDriving {
    private let csvProvider: BKRawCsvProvider
    private let barParser: any BKBarParsing

    /// Creates a new instance.
    public init(
        csvProvider: BKRawCsvProvider,
        barParser: any BKBarParsing = BKCSVBarParser()
    ) {
        self.csvProvider = csvProvider
        self.barParser = barParser
    }

    /// Executes `simulateInstrument`.
    public func simulateInstrument(
        instrumentID: String,
        config: BKV2.SimulationPolicyConfig,
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        csvColumnMapping: BKCSVColumnMapping? = nil
    ) async -> Result<(BKV2.SimulateConfigOutput, PositionStatus), BKEngineFailure> {
        let ticker = instrumentID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ticker.isEmpty else {
            return .failure(BKErrorMapper.map(instrumentID: instrumentID, error: BKSimulationDriverError.emptyInstrumentID))
        }
        let csv: String
        switch mapResult(await csvProvider.getRawCsv(ticker: ticker, p1: p1, p2: p2), instrumentID: ticker) {
        case .success(let rawCsv):
            csv = rawCsv
        case .failure(let error):
            return .failure(error)
        }
        let bars: [BKBar]
        switch mapResult(barParser.parse(csv: csv, dateFormat: dateFormat, columnMapping: csvColumnMapping), instrumentID: ticker) {
        case .success(let parsedBars):
            bars = parsedBars
        case .failure(let error):
            return .failure(error)
        }
        guard bars.count > 1 else {
            return .failure(BKErrorMapper.map(instrumentID: ticker, error: BKSimulationDriverError.emptyBars(ticker)))
        }
        return .success(v2simulateConfig(
            ticker: ticker,
            config: config,
            entryRules: config.entryRules,
            exitRules: config.exitRules,
            rawBars: bars
        ))
    }

    private func mapResult<T>(_ result: Result<T, Error>, instrumentID: String) -> Result<T, BKEngineFailure> {
        result.mapError { BKErrorMapper.map(instrumentID: instrumentID, error: $0) }
    }

    private func mapResult<T>(_ result: Result<T, BKCSVParsingError>, instrumentID: String) -> Result<T, BKEngineFailure> {
        result.mapError { BKErrorMapper.map(instrumentID: instrumentID, error: $0) }
    }
}
