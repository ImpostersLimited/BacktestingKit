import Foundation

public func runWeeklySimulation(
    instruments: [ATV3_InstrumentInfo],
    driver: ATSimulationDriver
) async throws {
    try await driver.simulateInstruments(instruments)
}

