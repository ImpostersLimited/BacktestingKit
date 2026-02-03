import Foundation

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
        let csv = try await csvProvider.getRawCsv(ticker: instrument.id, p1: p1, p2: p2)
        let bars = csvToBars(csv, dateFormat: dateFormat, reverse: true)
        guard bars.count > 1 else { return }

        let configs = try await dataStore.getConfigs(instrumentID: instrument.id)
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
                entryRules = presetRules.0.map { convertSimulationRule($0, type: "entry", configID: config.id, tickerID: instrument.id) }
                exitRules = presetRules.1.map { convertSimulationRule($0, type: "exit", configID: config.id, tickerID: instrument.id) }
            }

            let (output, status) = v3simulateConfig(
                ticker: instrument.id,
                config: config,
                entryRules: entryRules,
                exitRules: exitRules,
                rawBars: bars
            )

            let newAnalysis = convertAnalysis(output.analysis, configID: config.id, tickerID: instrument.id)
            let (newTrades, newRisks) = convertTradesWithRisks(output.trades, configID: config.id, tickerID: instrument.id)

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
        for instrument in instruments {
            try await simulateInstrument(instrument, p1: p1, p2: p2, dateFormat: dateFormat)
        }
    }
}
