import Foundation

// TODO: Replace this demo helper with proper unit tests or remove for production use.
public func runDemoSimulation(
    csv: String,
    instrumentID: String,
    config: ATV3_Config,
    entryRules: [ATV3_SimulationRule],
    exitRules: [ATV3_SimulationRule],
    dateFormat: String = "yyyy-MM-dd"
) -> (V3SimulateConfigOutput, PositionStatus) {
    let bars = csvToBars(csv, dateFormat: dateFormat, reverse: true)
    return v3simulateConfig(
        ticker: instrumentID,
        config: config,
        entryRules: entryRules,
        exitRules: exitRules,
        rawBars: bars
    )
}

