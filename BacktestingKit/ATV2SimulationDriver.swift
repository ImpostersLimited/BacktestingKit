import Foundation

public final class ATV2SimulationDriver {
    private let csvProvider: ATRawCsvProvider

    public init(csvProvider: ATRawCsvProvider) {
        self.csvProvider = csvProvider
    }

    public func simulateInstrument(
        instrumentID: String,
        config: ATV2.SimulationPolicyConfig,
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd"
    ) async throws -> (ATV2.SimulateConfigOutput, PositionStatus) {
        let ticker = instrumentID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ticker.isEmpty else {
            throw ATSimulationDriverError.emptyInstrumentID
        }
        let csv = try await csvProvider.getRawCsv(ticker: ticker, p1: p1, p2: p2)
        let bars = csvToBars(csv, dateFormat: dateFormat, reverse: true)
        guard bars.count > 1 else {
            throw ATSimulationDriverError.emptyBars(ticker)
        }
        return v2simulateConfig(
            ticker: ticker,
            config: config,
            entryRules: config.entryRules,
            exitRules: config.exitRules,
            rawBars: bars
        )
    }
}
