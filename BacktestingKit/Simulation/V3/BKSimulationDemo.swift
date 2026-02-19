import Foundation

// TODO: Replace this demo helper with proper unit tests or remove for production use.
/// Executes `runDemoSimulation`.
public func runDemoSimulation(
    csv: String,
    instrumentID: String,
    config: BKV3_Config,
    entryRules: [BKV3_SimulationRule],
    exitRules: [BKV3_SimulationRule],
    dateFormat: String = "yyyy-MM-dd",
    csvColumnMapping: BKCSVColumnMapping? = nil
) -> Result<(V3SimulateConfigOutput, PositionStatus), BKEngineFailure> {
    let bars: [BKBar]
    switch csvToBars(
        csv,
        dateFormat: dateFormat,
        reverse: false,
        columnMapping: csvColumnMapping
    ) {
    case .success(let parsed):
        bars = parsed
    case .failure(let error):
        return .failure(BKErrorMapper.map(instrumentID: instrumentID, error: error))
    }
    return .success(v3simulateConfig(
        ticker: instrumentID,
        config: config,
        entryRules: entryRules,
        exitRules: exitRules,
        rawBars: bars
    ))
}
