import Foundation

/// Executes `runWeeklySimulation`.
public func runWeeklySimulation(
    instruments: [BKV3_InstrumentInfo],
    driver: BKSimulationDriver
) async -> Result<Void, BKEngineFailure> {
    await driver.simulateInstruments(instruments)
}
