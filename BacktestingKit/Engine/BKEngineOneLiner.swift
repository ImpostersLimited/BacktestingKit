import Foundation

/// Represents `BKEngineOneLiner` in the BacktestingKit public API.
public enum BKEngineOneLiner {
    /// Shared component graph used by the one-liner engine entrypoints.
    public static var components = BKEngineComponentGraph()

    /// Factory closure used to build v3 drivers for one-liner execution.
    public static var makeV3Driver: @Sendable (_ dataStore: BKV3DataStore, _ csvProvider: BKRawCsvProvider) -> any BKV3SimulationDriving = { dataStore, csvProvider in
        components.simulationFactory.makeV3Driver(dataStore: dataStore, csvProvider: csvProvider)
    }

    /// Factory closure used to build v2 drivers for one-liner execution.
    public static var makeV2Driver: @Sendable (_ csvProvider: BKRawCsvProvider) -> any BKV2SimulationDriving = { csvProvider in
        components.simulationFactory.makeV2Driver(csvProvider: csvProvider)
    }

    /// Represents `BKV3Request` in the BacktestingKit public API.
    public struct BKV3Request {
        /// Instrument associated with this value.
        public var instrument: BKV3_InstrumentInfo
        /// P1 associated with this value.
        public var p1: Double
        /// P2 associated with this value.
        public var p2: Double
        /// Date format string used while parsing or formatting input.
        public var dateFormat: String
        /// Execution options associated with this value.
        public var executionOptions: BKSimulationExecutionOptions
        /// Data store associated with this value.
        public var dataStore: BKV3DataStore
        /// CSV provider associated with this value.
        public var csvProvider: BKRawCsvProvider
        /// Log associated with this value.
        public var log: (@Sendable (String) -> Void)?

        /// Creates a request object for a single v3 simulation run.
        ///
        /// - Parameters:
        ///   - instrument: Instrument metadata and configuration lookup key.
        ///   - p1: Lower bound used by provider-backed date window selection.
        ///   - p2: Upper bound used by provider-backed date window selection.
        ///   - dateFormat: Date format hint forwarded to the simulation driver.
        ///   - executionOptions: Driver options controlling parsing and run behavior.
        ///   - dataStore: v3 persistence layer used to load configs and save results.
        ///   - csvProvider: Raw CSV provider used to fetch market data for the run.
        ///   - log: Optional log sink for lifecycle messages.
        public init(
            instrument: BKV3_InstrumentInfo,
            p1: Double = 5.0,
            p2: Double = 6.0,
            dateFormat: String = "yyyy-MM-dd",
            executionOptions: BKSimulationExecutionOptions = BKSimulationExecutionOptions(),
            dataStore: BKV3DataStore,
            csvProvider: BKRawCsvProvider,
            log: (@Sendable (String) -> Void)? = nil
        ) {
            self.instrument = instrument
            self.p1 = p1
            self.p2 = p2
            self.dateFormat = dateFormat
            self.executionOptions = executionOptions
            self.dataStore = dataStore
            self.csvProvider = csvProvider
            self.log = log
        }
    }

    /// Represents `BKV2Request` in the BacktestingKit public API.
    public struct BKV2Request {
        /// Identifier associated with this value.
        public var instrumentID: String
        /// Configuration associated with this value.
        public var config: BKV2.SimulationPolicyConfig
        /// P1 associated with this value.
        public var p1: Double
        /// P2 associated with this value.
        public var p2: Double
        /// Date format string used while parsing or formatting input.
        public var dateFormat: String
        /// CSV column mapping associated with this value.
        public var csvColumnMapping: BKCSVColumnMapping?
        /// CSV provider associated with this value.
        public var csvProvider: BKRawCsvProvider
        /// Log associated with this value.
        public var log: (@Sendable (String) -> Void)?

        /// Creates a request object for a single v2 simulation run.
        ///
        /// - Parameters:
        ///   - instrumentID: Identifier or ticker to simulate.
        ///   - config: v2 policy configuration passed to the simulation engine.
        ///   - p1: Lower bound used by provider-backed date window selection.
        ///   - p2: Upper bound used by provider-backed date window selection.
        ///   - dateFormat: Date format hint forwarded to the simulation driver.
        ///   - csvColumnMapping: Optional CSV header overrides for custom datasets.
        ///   - csvProvider: Raw CSV provider used to fetch market data for the run.
        ///   - log: Optional log sink for lifecycle messages.
        public init(
            instrumentID: String,
            config: BKV2.SimulationPolicyConfig,
            p1: Double = 5.0,
            p2: Double = 6.0,
            dateFormat: String = "yyyy-MM-dd",
            csvColumnMapping: BKCSVColumnMapping? = nil,
            csvProvider: BKRawCsvProvider,
            log: (@Sendable (String) -> Void)? = nil
        ) {
            self.instrumentID = instrumentID
            self.config = config
            self.p1 = p1
            self.p2 = p2
            self.dateFormat = dateFormat
            self.csvColumnMapping = csvColumnMapping
            self.csvProvider = csvProvider
            self.log = log
        }
    }

    /// Runs a v3 request and returns the instrument-level simulation report.
    public static func runBKV3(_ request: BKV3Request) async -> Result<BKSimulationInstrumentReport, BKEngineFailure> {
        request.log?("[OneLiner][V3] Start instrument=\(request.instrument.id)")
        let driver = makeV3Driver(request.dataStore, request.csvProvider)
        let result = await driver.simulateInstrumentDetailed(
            request.instrument,
            p1: request.p1,
            p2: request.p2,
            dateFormat: request.dateFormat,
            executionOptions: request.executionOptions
        )
        switch result {
        case .success(let report):
            request.log?("[OneLiner][V3] Success instrument=\(request.instrument.id), configs=\(report.configCountProcessed), trades=\(report.tradeCount)")
            return .success(report)
        case .failure(let failure):
            request.log?("[OneLiner][V3] Failed instrument=\(request.instrument.id), code=\(failure.code.rawValue), stage=\(failure.stage), message=\(failure.message)")
            return .failure(failure)
        }
    }

    /// Runs a v2 request and returns the raw simulation output and ending position status.
    public static func runBKV2(_ request: BKV2Request) async -> Result<(BKV2.SimulateConfigOutput, PositionStatus), BKEngineFailure> {
        request.log?("[OneLiner][V2] Start instrument=\(request.instrumentID)")
        let driver = makeV2Driver(request.csvProvider)
        let result = await driver.simulateInstrument(
            instrumentID: request.instrumentID,
            config: request.config,
            p1: request.p1,
            p2: request.p2,
            dateFormat: request.dateFormat,
            csvColumnMapping: request.csvColumnMapping
        )
        switch result {
        case .success(let output):
            request.log?("[OneLiner][V2] Success instrument=\(request.instrumentID), status=\(output.1.rawValue), trades=\(output.0.trades.count)")
            return .success(output)
        case .failure(let failure):
            request.log?("[OneLiner][V2] Failed instrument=\(request.instrumentID), code=\(failure.code.rawValue), stage=\(failure.stage), message=\(failure.message)")
            return .failure(failure)
        }
    }

    /// Convenience alias for `runBKV3(_:)`.
    public static func runV3(_ request: BKV3Request) async -> Result<BKSimulationInstrumentReport, BKEngineFailure> {
        await runBKV3(request)
    }

    /// Convenience alias for `runBKV2(_:)`.
    public static func runV2(_ request: BKV2Request) async -> Result<(BKV2.SimulateConfigOutput, PositionStatus), BKEngineFailure> {
        await runBKV2(request)
    }

    /// Backward-compatible alias for `runBKV3(_:)`.
    public static func runATV3(_ request: BKV3Request) async -> Result<BKSimulationInstrumentReport, BKEngineFailure> {
        await runBKV3(request)
    }

    /// Backward-compatible alias for `runBKV2(_:)`.
    public static func runATV2(_ request: BKV2Request) async -> Result<(BKV2.SimulateConfigOutput, PositionStatus), BKEngineFailure> {
        await runBKV2(request)
    }
}

/// Provides the `BKEngineV3Request` typealias for BacktestingKit interoperability.
public typealias BKEngineV3Request = BKEngineOneLiner.BKV3Request

/// Provides the `BKEngineV2Request` typealias for BacktestingKit interoperability.
public typealias BKEngineV2Request = BKEngineOneLiner.BKV2Request
