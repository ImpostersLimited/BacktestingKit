import Foundation

/// Component-level factory for simulation drivers.
public protocol BKSimulationDriverFactory: Sendable {
    func makeV3Driver(dataStore: BKV3DataStore, csvProvider: BKRawCsvProvider) -> any BKV3SimulationDriving
    func makeV2Driver(csvProvider: BKRawCsvProvider) -> any BKV2SimulationDriving
}

/// Default component implementation used by `BKEngine` and one-liner APIs.
public struct BKDefaultSimulationDriverFactory: BKSimulationDriverFactory {
    /// Creates a new instance.
    public init() {}

    /// Executes `makeV3Driver`.
    public func makeV3Driver(
        dataStore: BKV3DataStore,
        csvProvider: BKRawCsvProvider
    ) -> any BKV3SimulationDriving {
        BKSimulationDriver(dataStore: dataStore, csvProvider: csvProvider)
    }

    /// Executes `makeV2Driver`.
    public func makeV2Driver(csvProvider: BKRawCsvProvider) -> any BKV2SimulationDriving {
        BKV2SimulationDriver(csvProvider: csvProvider)
    }
}

/// Single source of truth for engine components.
public struct BKEngineComponentGraph: Sendable {
    public var simulationFactory: any BKSimulationDriverFactory

    /// Creates a new instance.
    public init(simulationFactory: any BKSimulationDriverFactory = BKDefaultSimulationDriverFactory()) {
        self.simulationFactory = simulationFactory
    }
}
