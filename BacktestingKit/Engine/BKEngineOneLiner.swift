import Foundation

/// Represents `BKEngineOneLiner` in the BacktestingKit public API.
public enum BKEngineOneLiner {
    public static var components = BKEngineComponentGraph()

    public static var makeV3Driver: @Sendable (_ dataStore: BKV3DataStore, _ csvProvider: BKRawCsvProvider) -> any BKV3SimulationDriving = { dataStore, csvProvider in
        components.simulationFactory.makeV3Driver(dataStore: dataStore, csvProvider: csvProvider)
    }

    public static var makeV2Driver: @Sendable (_ csvProvider: BKRawCsvProvider) -> any BKV2SimulationDriving = { csvProvider in
        components.simulationFactory.makeV2Driver(csvProvider: csvProvider)
    }

    /// Represents `BKV3Request` in the BacktestingKit public API.
    public struct BKV3Request {
        public var instrument: BKV3_InstrumentInfo
        public var p1: Double
        public var p2: Double
        public var dateFormat: String
        public var executionOptions: BKSimulationExecutionOptions
        public var dataStore: BKV3DataStore
        public var csvProvider: BKRawCsvProvider
        public var log: (@Sendable (String) -> Void)?

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
        public var instrumentID: String
        public var config: BKV2.SimulationPolicyConfig
        public var p1: Double
        public var p2: Double
        public var dateFormat: String
        public var csvColumnMapping: BKCSVColumnMapping?
        public var csvProvider: BKRawCsvProvider
        public var log: (@Sendable (String) -> Void)?

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

    public static func runV3(_ request: BKV3Request) async -> Result<BKSimulationInstrumentReport, BKEngineFailure> {
        await runBKV3(request)
    }

    public static func runV2(_ request: BKV2Request) async -> Result<(BKV2.SimulateConfigOutput, PositionStatus), BKEngineFailure> {
        await runBKV2(request)
    }

    public static func runATV3(_ request: BKV3Request) async -> Result<BKSimulationInstrumentReport, BKEngineFailure> {
        await runBKV3(request)
    }

    public static func runATV2(_ request: BKV2Request) async -> Result<(BKV2.SimulateConfigOutput, PositionStatus), BKEngineFailure> {
        await runBKV2(request)
    }
}

/// Provides the `BKEngineV3Request` typealias for BacktestingKit interoperability.
public typealias BKEngineV3Request = BKEngineOneLiner.BKV3Request

/// Provides the `BKEngineV2Request` typealias for BacktestingKit interoperability.
public typealias BKEngineV2Request = BKEngineOneLiner.BKV2Request
