import Foundation

public func runDailySimulation(
    instruments: [ATV3_InstrumentInfo],
    driver: ATSimulationDriver
) async throws {
    try await driver.simulateInstruments(instruments)
}

