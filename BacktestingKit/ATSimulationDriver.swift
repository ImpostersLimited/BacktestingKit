import Foundation

public enum ATSimulationDriverError: LocalizedError, Equatable {
    case emptyInstrumentID
    case emptyBars(String)
    case invalidConcurrency(Int)

    public var errorDescription: String? {
        switch self {
        case .emptyInstrumentID:
            return "Instrument ID must not be empty."
        case .emptyBars(let ticker):
            return "No valid bars were parsed for instrument '\(ticker)'."
        case .invalidConcurrency(let value):
            return "maxConcurrency must be >= 1, received \(value)."
        }
    }
}

public struct ATSimulationRunFailure: Error, Equatable {
    public var instrumentID: String
    public var message: String

    public init(instrumentID: String, message: String) {
        self.instrumentID = instrumentID
        self.message = message
    }
}

public final class ATSimulationDriver {
    private let dataStore: ATV3DataStore
    private let csvProvider: ATRawCsvProvider

    public init(dataStore: ATV3DataStore, csvProvider: ATRawCsvProvider) {
        self.dataStore = dataStore
        self.csvProvider = csvProvider
    }

    public func simulateInstrument(
        _ instrument: ATV3_InstrumentInfo,
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd"
    ) async throws {
        let ticker = instrument.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ticker.isEmpty else {
            throw ATSimulationDriverError.emptyInstrumentID
        }
        let csv = try await csvProvider.getRawCsv(ticker: ticker, p1: p1, p2: p2)
        let bars = csvToBars(csv, dateFormat: dateFormat, reverse: true)
        guard bars.count > 1 else {
            throw ATSimulationDriverError.emptyBars(ticker)
        }

        let configs = try await dataStore.getConfigs(instrumentID: ticker)
        if configs.isEmpty { return }

        for config in configs {
            guard let policy = config.policy else { continue }
            var entryRules: [ATV3_SimulationRule] = []
            var exitRules: [ATV3_SimulationRule] = []

            if policy == .customStrategy {
                entryRules = try await dataStore.getSimulationRules(configID: config.id, ruleType: "entry")
                if entryRules.isEmpty { continue }
                exitRules = try await dataStore.getSimulationRules(configID: config.id, ruleType: "exit")
                if exitRules.isEmpty { continue }
            } else {
                let presetRules = v3GetPresetRules(preset: policy)
                entryRules = presetRules.0.map { convertSimulationRule($0, type: "entry", configID: config.id, tickerID: ticker) }
                exitRules = presetRules.1.map { convertSimulationRule($0, type: "exit", configID: config.id, tickerID: ticker) }
            }

            let (output, status) = v3simulateConfig(
                ticker: ticker,
                config: config,
                entryRules: entryRules,
                exitRules: exitRules,
                rawBars: bars
            )

            let newAnalysis = convertAnalysis(output.analysis, configID: config.id, tickerID: ticker)
            let (newTrades, newRisks) = convertTradesWithRisks(output.trades, configID: config.id, tickerID: ticker)

            var updatedConfig = config
            updatedConfig.lastStatus = status
            updatedConfig.lastUpdated = Date()

            let finalRules = entryRules + exitRules
            try await dataStore.saveConfig(updatedConfig)
            try await dataStore.saveAnalysis(newAnalysis)
            try await dataStore.saveTrades(newTrades)
            if policy == .customStrategy {
                try await dataStore.saveSimulationRules(finalRules)
            }
            try await dataStore.saveRisks(newRisks)
        }
    }

    public func simulateInstruments(
        _ instruments: [ATV3_InstrumentInfo],
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd"
    ) async throws {
        let failures = try await simulateInstrumentsCollectingFailures(
            instruments,
            p1: p1,
            p2: p2,
            dateFormat: dateFormat,
            maxConcurrency: 1
        )
        if let firstFailure = failures.first {
            throw firstFailure
        }
    }

    public func simulateInstrumentsCollectingFailures(
        _ instruments: [ATV3_InstrumentInfo],
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        maxConcurrency: Int = 4
    ) async throws -> [ATSimulationRunFailure] {
        guard maxConcurrency >= 1 else {
            throw ATSimulationDriverError.invalidConcurrency(maxConcurrency)
        }
        if instruments.isEmpty {
            return []
        }

        var failures: [ATSimulationRunFailure] = []
        var nextIndex = 0

        try await withThrowingTaskGroup(of: (String, Error?).self) { group in
            while nextIndex < instruments.count && nextIndex < maxConcurrency {
                let instrument = instruments[nextIndex]
                nextIndex += 1
                group.addTask {
                    do {
                        try await self.simulateInstrument(instrument, p1: p1, p2: p2, dateFormat: dateFormat)
                        return (instrument.id, nil)
                    } catch {
                        return (instrument.id, error)
                    }
                }
            }

            while let (instrumentID, maybeError) = try await group.next() {
                if let error = maybeError {
                    failures.append(ATSimulationRunFailure(instrumentID: instrumentID, message: String(describing: error)))
                }
                if nextIndex < instruments.count {
                    let instrument = instruments[nextIndex]
                    nextIndex += 1
                    group.addTask {
                        do {
                            try await self.simulateInstrument(instrument, p1: p1, p2: p2, dateFormat: dateFormat)
                            return (instrument.id, nil)
                        } catch {
                            return (instrument.id, error)
                        }
                    }
                }
            }
        }

        return failures
    }
}
