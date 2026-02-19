import Foundation

/// Executes `runDailySimulation`.
public func runDailySimulation(
    instruments: [BKV3_InstrumentInfo],
    driver: BKSimulationDriver
) async -> Result<Void, BKEngineFailure> {
    await driver.simulateInstruments(instruments)
}
