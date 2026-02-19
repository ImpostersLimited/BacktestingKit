import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// Represents `BKSimulationDriverError` in the BacktestingKit public API.
public enum BKSimulationDriverError: LocalizedError, Equatable {
    case emptyInstrumentID
    case emptyBars(String)
    case invalidConcurrency(Int)

    public var errorDescription: String? {
        switch self {
        case .emptyInstrumentID:
            return "Instrument ID must not be empty."
        case .emptyBars(let ticker):
            return "No valid bars were parsed for instrument '\(ticker)'."
        case .invalidConcurrency(let value):
            return "maxConcurrency must be >= 1, received \(value)."
        }
    }
}

/// Represents `BKEngineErrorCode` in the BacktestingKit public API.
public enum BKEngineErrorCode: String, Codable, Equatable {
    case invalidInput
    case network
    case dataParsing
    case datastore
    case simulation
    case unknown
}

/// Represents `BKSimulationRunFailure` in the BacktestingKit public API.
public struct BKSimulationRunFailure: Error, Equatable {
    public var instrumentID: String
    public var message: String

    /// Creates a new instance.
    public init(instrumentID: String, message: String) {
        self.instrumentID = instrumentID
        self.message = message
    }
}

/// Represents `BKEngineFailure` in the BacktestingKit public API.
public struct BKEngineFailure: Error, Equatable, Codable {
    public var instrumentID: String
    public var code: BKEngineErrorCode
    public var stage: String
    public var message: String
    public var isRetryable: Bool
    public var timestamp: Date
    public var metadata: [String: String]
    public var recoverySuggestion: String?

    /// Creates a new instance.
    public init(
        instrumentID: String,
        code: BKEngineErrorCode,
        stage: String,
        message: String,
        isRetryable: Bool = false,
        timestamp: Date = Date(),
        metadata: [String: String] = [:],
        recoverySuggestion: String? = nil
    ) {
        self.instrumentID = instrumentID
        self.code = code
        self.stage = stage
        self.message = message
        self.isRetryable = isRetryable
        self.timestamp = timestamp
        self.metadata = metadata
        self.recoverySuggestion = recoverySuggestion
    }
}

/// Represents `BKSimulationBatchOptions` in the BacktestingKit public API.
public struct BKSimulationBatchOptions: Equatable, Codable {
    public var maxConcurrency: Int
    public var continueOnFailure: Bool
    public var useStreamingCsvParser: Bool
    public var strictCsvParsing: Bool
    public var csvColumnMapping: BKCSVColumnMapping?

    /// Creates a new instance.
    public init(
        maxConcurrency: Int = 4,
        continueOnFailure: Bool = true,
        useStreamingCsvParser: Bool = false,
        strictCsvParsing: Bool = false,
        csvColumnMapping: BKCSVColumnMapping? = nil
    ) {
        self.maxConcurrency = max(1, maxConcurrency)
        self.continueOnFailure = continueOnFailure
        self.useStreamingCsvParser = useStreamingCsvParser
        self.strictCsvParsing = strictCsvParsing
        self.csvColumnMapping = csvColumnMapping
    }
}

/// Represents `BKSimulationBatchReport` in the BacktestingKit public API.
public struct BKSimulationBatchReport: Equatable, Codable {
    public var totalInstruments: Int
    public var succeeded: Int
    public var failed: Int
    public var elapsedMS: Double
    public var memoryDeltaBytes: UInt64?
    public var failures: [BKEngineFailure]

    /// Creates a new instance.
    public init(
        totalInstruments: Int,
        succeeded: Int,
        failed: Int,
        elapsedMS: Double,
        memoryDeltaBytes: UInt64?,
        failures: [BKEngineFailure]
    ) {
        self.totalInstruments = totalInstruments
        self.succeeded = succeeded
        self.failed = failed
        self.elapsedMS = elapsedMS
        self.memoryDeltaBytes = memoryDeltaBytes
        self.failures = failures
    }
}

/// Represents `BKCSVParserMode` in the BacktestingKit public API.
public enum BKCSVParserMode: String, Codable, Equatable {
    case legacy
    case streamingLenient
    case streamingStrict
}

/// Represents `BKSimulationExecutionOptions` in the BacktestingKit public API.
public struct BKSimulationExecutionOptions: Equatable, Codable {
    public var parserMode: BKCSVParserMode
    public var maxBarsPerInstrument: Int?
    public var csvColumnMapping: BKCSVColumnMapping?

    /// Creates a new instance.
    public init(
        parserMode: BKCSVParserMode = .legacy,
        maxBarsPerInstrument: Int? = nil,
        csvColumnMapping: BKCSVColumnMapping? = nil
    ) {
        self.parserMode = parserMode
        self.maxBarsPerInstrument = maxBarsPerInstrument
        self.csvColumnMapping = csvColumnMapping
    }
}

/// Represents `BKSimulationInstrumentReport` in the BacktestingKit public API.
public struct BKSimulationInstrumentReport: Equatable, Codable {
    public var instrumentID: String
    public var elapsedMS: Double
    public var configCountProcessed: Int
    public var tradeCount: Int
    public var riskPointCount: Int

    /// Creates a new instance.
    public init(
        instrumentID: String,
        elapsedMS: Double,
        configCountProcessed: Int,
        tradeCount: Int,
        riskPointCount: Int
    ) {
        self.instrumentID = instrumentID
        self.elapsedMS = elapsedMS
        self.configCountProcessed = configCountProcessed
        self.tradeCount = tradeCount
        self.riskPointCount = riskPointCount
    }
}

/// Represents `BKSimulationProgress` in the BacktestingKit public API.
public struct BKSimulationProgress: Equatable, Codable {
    public var completed: Int
    public var total: Int
    public var succeeded: Int
    public var failed: Int
    public var lastInstrumentID: String

    /// Creates a new instance.
    public init(
        completed: Int,
        total: Int,
        succeeded: Int,
        failed: Int,
        lastInstrumentID: String
    ) {
        self.completed = completed
        self.total = total
        self.succeeded = succeeded
        self.failed = failed
        self.lastInstrumentID = lastInstrumentID
    }
}

/// Represents `BKSimulationBatchDetailedReport` in the BacktestingKit public API.
public struct BKSimulationBatchDetailedReport: Equatable, Codable {
    public var summary: BKSimulationBatchReport
    public var instrumentReports: [BKSimulationInstrumentReport]

    /// Creates a new instance.
    public init(summary: BKSimulationBatchReport, instrumentReports: [BKSimulationInstrumentReport]) {
        self.summary = summary
        self.instrumentReports = instrumentReports
    }
}

/// Represents `BKSimulationBatchRunHandle` in the BacktestingKit public API.
public struct BKSimulationBatchRunHandle {
    public var progressStream: AsyncStream<BKSimulationProgress>
    public var resultTask: Task<BKSimulationBatchDetailedReport, Never>

    /// Creates a new instance.
    public init(
        progressStream: AsyncStream<BKSimulationProgress>,
        resultTask: Task<BKSimulationBatchDetailedReport, Never>
    ) {
        self.progressStream = progressStream
        self.resultTask = resultTask
    }
}

public final class BKSimulationDriver: BKV3SimulationDriving {
    private let dataStore: BKV3DataStore
    private let csvProvider: BKRawCsvProvider
    private let barParser: any BKBarParsing

    /// Creates a new instance.
    public init(
        dataStore: BKV3DataStore,
        csvProvider: BKRawCsvProvider,
        barParser: any BKBarParsing = BKCSVBarParser()
    ) {
        self.dataStore = dataStore
        self.csvProvider = csvProvider
        self.barParser = barParser
    }

    /// Executes `simulateInstrument`.
    public func simulateInstrument(
        _ instrument: BKV3_InstrumentInfo,
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd"
    ) async -> Result<Void, BKEngineFailure> {
        switch await simulateInstrumentDetailed(
            instrument,
            p1: p1,
            p2: p2,
            dateFormat: dateFormat,
            executionOptions: BKSimulationExecutionOptions(parserMode: .legacy)
        ) {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Executes `simulateInstruments`.
    public func simulateInstruments(
        _ instruments: [BKV3_InstrumentInfo],
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd"
    ) async -> Result<Void, BKEngineFailure> {
        let failuresResult = await simulateInstrumentsCollectingFailures(
            instruments,
            p1: p1,
            p2: p2,
            dateFormat: dateFormat,
            maxConcurrency: 1
        )
        switch failuresResult {
        case .success(let failures):
            if let firstFailure = failures.first {
                return .failure(
                    BKEngineFailure(
                        instrumentID: firstFailure.instrumentID,
                        code: .simulation,
                        stage: "simulateInstruments",
                        message: firstFailure.message
                    )
                )
            }
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Executes `simulateInstrumentsCollectingFailures`.
    public func simulateInstrumentsCollectingFailures(
        _ instruments: [BKV3_InstrumentInfo],
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        maxConcurrency: Int = 4
    ) async -> Result<[BKSimulationRunFailure], BKEngineFailure> {
        guard maxConcurrency >= 1 else {
            return .failure(
                BKErrorMapper.map(
                    instrumentID: "",
                    error: BKSimulationDriverError.invalidConcurrency(maxConcurrency)
                )
            )
        }
        if instruments.isEmpty {
            return .success([])
        }

        var failures: [BKSimulationRunFailure] = []
        var nextIndex = 0

        await withTaskGroup(of: (String, Error?).self) { group in
            while nextIndex < instruments.count && nextIndex < maxConcurrency {
                let instrument = instruments[nextIndex]
                nextIndex += 1
                group.addTask {
                    let result = await self.simulateInstrument(instrument, p1: p1, p2: p2, dateFormat: dateFormat)
                    switch result {
                    case .success:
                        return (instrument.id, nil)
                    case .failure(let error):
                        return (instrument.id, error)
                    }
                }
            }

            while let (instrumentID, maybeError) = await group.next() {
                if Task.isCancelled {
                    group.cancelAll()
                    break
                }
                if let error = maybeError {
                    failures.append(BKSimulationRunFailure(instrumentID: instrumentID, message: String(describing: error)))
                }
                if nextIndex < instruments.count {
                    let instrument = instruments[nextIndex]
                    nextIndex += 1
                    group.addTask {
                        let result = await self.simulateInstrument(instrument, p1: p1, p2: p2, dateFormat: dateFormat)
                        switch result {
                        case .success:
                            return (instrument.id, nil)
                        case .failure(let error):
                            return (instrument.id, error)
                        }
                    }
                }
            }
        }

        return .success(failures)
    }

    /// Executes `simulateInstrumentsWithReport`.
    public func simulateInstrumentsWithReport(
        _ instruments: [BKV3_InstrumentInfo],
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        options: BKSimulationBatchOptions = BKSimulationBatchOptions()
    ) async -> BKSimulationBatchReport {
        let detailed = await simulateInstrumentsWithDetailedReport(
            instruments,
            p1: p1,
            p2: p2,
            dateFormat: dateFormat,
            batchOptions: options,
            executionOptions: BKSimulationExecutionOptions(
                parserMode: options.useStreamingCsvParser ? (options.strictCsvParsing ? .streamingStrict : .streamingLenient) : .legacy,
                csvColumnMapping: options.csvColumnMapping
            )
        )
        return detailed.summary
    }

    /// Executes `simulateInstrumentsWithDetailedReport`.
    public func simulateInstrumentsWithDetailedReport(
        _ instruments: [BKV3_InstrumentInfo],
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        batchOptions: BKSimulationBatchOptions = BKSimulationBatchOptions(),
        executionOptions: BKSimulationExecutionOptions = BKSimulationExecutionOptions(),
        progress: (@Sendable (BKSimulationProgress) -> Void)? = nil
    ) async -> BKSimulationBatchDetailedReport {
        let start = Date()
        let startMemory = currentResidentMemoryBytes()
        if instruments.isEmpty {
            return BKSimulationBatchDetailedReport(
                summary: BKSimulationBatchReport(
                    totalInstruments: 0,
                    succeeded: 0,
                    failed: 0,
                    elapsedMS: 0,
                    memoryDeltaBytes: 0,
                    failures: []
                ),
                instrumentReports: []
            )
        }

        var failures: [BKEngineFailure] = []
        var instrumentReports: [BKSimulationInstrumentReport] = []
        var succeeded = 0
        var completed = 0
        var nextIndex = 0
        let concurrency = max(1, batchOptions.maxConcurrency)
        let inputOrder: [String: Int] = Dictionary(uniqueKeysWithValues: instruments.enumerated().map { ($1.id, $0) })

        await withTaskGroup(of: (String, Result<BKSimulationInstrumentReport, BKEngineFailure>).self) { group in
            func enqueue(_ instrument: BKV3_InstrumentInfo) {
                group.addTask {
                    let result = await self.simulateInstrumentDetailed(
                        instrument,
                        p1: p1,
                        p2: p2,
                        dateFormat: dateFormat,
                        executionOptions: executionOptions
                    )
                    return (instrument.id, result)
                }
            }

            while nextIndex < instruments.count && nextIndex < concurrency {
                enqueue(instruments[nextIndex])
                nextIndex += 1
            }

            while let (instrumentID, result) = await group.next() {
                if Task.isCancelled {
                    failures.append(
                        BKEngineFailure(
                            instrumentID: instrumentID,
                            code: .simulation,
                            stage: "cancelled",
                            message: "Simulation batch was cancelled.",
                            recoverySuggestion: "Retry the batch if needed."
                        )
                    )
                    group.cancelAll()
                    break
                }
                completed += 1
                switch result {
                case .success(let report):
                    succeeded += 1
                    instrumentReports.append(report)
                case .failure(let error):
                    failures.append(mapFailure(instrumentID: instrumentID, error: error))
                    if !batchOptions.continueOnFailure {
                        group.cancelAll()
                    }
                }
                progress?(
                    BKSimulationProgress(
                        completed: completed,
                        total: instruments.count,
                        succeeded: succeeded,
                        failed: failures.count,
                        lastInstrumentID: instrumentID
                    )
                )

                if nextIndex < instruments.count && (batchOptions.continueOnFailure || failures.isEmpty) {
                    let instrument = instruments[nextIndex]
                    nextIndex += 1
                    enqueue(instrument)
                }
            }
        }

        let elapsedMS = Date().timeIntervalSince(start) * 1000
        let endMemory = currentResidentMemoryBytes()
        instrumentReports.sort { lhs, rhs in
            let left = inputOrder[lhs.instrumentID] ?? Int.max
            let right = inputOrder[rhs.instrumentID] ?? Int.max
            return left < right
        }
        failures.sort { lhs, rhs in
            let left = inputOrder[lhs.instrumentID] ?? Int.max
            let right = inputOrder[rhs.instrumentID] ?? Int.max
            return left < right
        }
        let delta: UInt64?
        if let startMemory, let endMemory {
            delta = endMemory >= startMemory ? (endMemory - startMemory) : 0
        } else {
            delta = nil
        }

        return BKSimulationBatchDetailedReport(
            summary: BKSimulationBatchReport(
                totalInstruments: instruments.count,
                succeeded: succeeded,
                failed: failures.count,
                elapsedMS: elapsedMS,
                memoryDeltaBytes: delta,
                failures: failures
            ),
            instrumentReports: instrumentReports
        )
    }

    /// Executes `startSimulationBatch`.
    public func startSimulationBatch(
        _ instruments: [BKV3_InstrumentInfo],
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        batchOptions: BKSimulationBatchOptions = BKSimulationBatchOptions(),
        executionOptions: BKSimulationExecutionOptions = BKSimulationExecutionOptions()
    ) -> BKSimulationBatchRunHandle {
        final class ProgressHolder {
            private let lock = NSLock()
            private var continuation: AsyncStream<BKSimulationProgress>.Continuation?

            func set(_ value: AsyncStream<BKSimulationProgress>.Continuation) {
                lock.lock(); continuation = value; lock.unlock()
            }

            func send(_ update: BKSimulationProgress) {
                lock.lock()
                continuation?.yield(update)
                lock.unlock()
            }

            func finish() {
                lock.lock()
                continuation?.finish()
                lock.unlock()
            }
        }

        let holder = ProgressHolder()
        let stream = AsyncStream<BKSimulationProgress> { streamContinuation in
            holder.set(streamContinuation)
        }

        let task = Task<BKSimulationBatchDetailedReport, Never> {
            let report = await simulateInstrumentsWithDetailedReport(
                instruments,
                p1: p1,
                p2: p2,
                dateFormat: dateFormat,
                batchOptions: batchOptions,
                executionOptions: executionOptions,
                progress: { update in
                    holder.send(update)
                }
            )
            holder.finish()
            return report
        }

        return BKSimulationBatchRunHandle(progressStream: stream, resultTask: task)
    }

    /// Executes `simulateInstrumentAdvanced`.
    public func simulateInstrumentAdvanced(
        _ instrument: BKV3_InstrumentInfo,
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        useStreamingCsvParser: Bool = false,
        strictCsvParsing: Bool = false,
        csvColumnMapping: BKCSVColumnMapping? = nil
    ) async -> Result<Void, BKEngineFailure> {
        switch await simulateInstrumentDetailed(
            instrument,
            p1: p1,
            p2: p2,
            dateFormat: dateFormat,
            executionOptions: BKSimulationExecutionOptions(
                parserMode: useStreamingCsvParser ? (strictCsvParsing ? .streamingStrict : .streamingLenient) : .legacy,
                csvColumnMapping: csvColumnMapping
            )
        ) {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Executes `simulateInstrumentDetailed`.
    public func simulateInstrumentDetailed(
        _ instrument: BKV3_InstrumentInfo,
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        executionOptions: BKSimulationExecutionOptions = BKSimulationExecutionOptions()
    ) async -> Result<BKSimulationInstrumentReport, BKEngineFailure> {
        if Task.isCancelled {
            return .failure(
                BKEngineFailure(
                    instrumentID: instrument.id,
                    code: .simulation,
                    stage: "cancelled",
                    message: "Simulation cancelled before start.",
                    recoverySuggestion: "Retry when resources are available."
                )
            )
        }
        let started = Date()
        let ticker = instrument.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ticker.isEmpty else {
            return .failure(BKErrorMapper.map(instrumentID: instrument.id, error: BKSimulationDriverError.emptyInstrumentID))
        }
        let csv: String
        switch mapDataStoreResult(await csvProvider.getRawCsv(ticker: ticker, p1: p1, p2: p2), instrumentID: ticker) {
        case .success(let value):
            csv = value
        case .failure(let error):
            return .failure(error)
        }
        let effectiveBars: [BKBar]
        switch mapParsingResult(barParser.parse(
            csv: csv,
            dateFormat: dateFormat,
            executionOptions: executionOptions
        ), instrumentID: ticker) {
        case .success(let bars):
            effectiveBars = bars
        case .failure(let error):
            return .failure(error)
        }
        guard effectiveBars.count > 1 else {
            return .failure(BKErrorMapper.map(instrumentID: ticker, error: BKSimulationDriverError.emptyBars(ticker)))
        }

        let configs: [BKV3_Config]
        switch mapDataStoreResult(await dataStore.getConfigs(instrumentID: ticker), instrumentID: ticker) {
        case .success(let loadedConfigs):
            configs = loadedConfigs
        case .failure(let error):
            return .failure(error)
        }
        if configs.isEmpty {
            return .success(BKSimulationInstrumentReport(
                instrumentID: ticker,
                elapsedMS: Date().timeIntervalSince(started) * 1000,
                configCountProcessed: 0,
                tradeCount: 0,
                riskPointCount: 0
            ))
        }

        var configCountProcessed = 0
        var tradeCount = 0
        var riskPointCount = 0

        for config in configs {
            if Task.isCancelled {
                return .failure(
                    BKEngineFailure(
                        instrumentID: ticker,
                        code: .simulation,
                        stage: "cancelled",
                        message: "Simulation cancelled while processing configs.",
                        recoverySuggestion: "Retry the request."
                    )
                )
            }
            guard let policy = config.policy else { continue }
            var entryRules: [BKV3_SimulationRule] = []
            var exitRules: [BKV3_SimulationRule] = []

            if policy == .customStrategy {
                switch mapDataStoreResult(await dataStore.getSimulationRules(configID: config.id, ruleType: "entry"), instrumentID: ticker) {
                case .success(let rules):
                    entryRules = rules
                case .failure(let error):
                    return .failure(error)
                }
                if entryRules.isEmpty { continue }
                switch mapDataStoreResult(await dataStore.getSimulationRules(configID: config.id, ruleType: "exit"), instrumentID: ticker) {
                case .success(let rules):
                    exitRules = rules
                case .failure(let error):
                    return .failure(error)
                }
                if exitRules.isEmpty { continue }
            } else {
                let presetRules = v3GetPresetRules(preset: policy)
                entryRules = presetRules.0.map { convertSimulationRule($0, type: "entry", configID: config.id, tickerID: ticker) }
                exitRules = presetRules.1.map { convertSimulationRule($0, type: "exit", configID: config.id, tickerID: ticker) }
            }

            let (output, status) = v3simulateConfig(
                ticker: ticker,
                config: config,
                entryRules: entryRules,
                exitRules: exitRules,
                rawBars: effectiveBars
            )

            let newAnalysis = convertAnalysis(output.analysis, configID: config.id, tickerID: ticker)
            let (newTrades, newRisks) = convertTradesWithRisks(output.trades, configID: config.id, tickerID: ticker)
            configCountProcessed += 1
            tradeCount += output.trades.count
            riskPointCount += newRisks.count

            var updatedConfig = config
            updatedConfig.lastStatus = status
            updatedConfig.lastUpdated = Date()

            let finalRules = entryRules + exitRules
            switch mapDataStoreResult(await dataStore.saveConfig(updatedConfig), instrumentID: ticker) {
            case .success:
                break
            case .failure(let error):
                return .failure(error)
            }
            switch mapDataStoreResult(await dataStore.saveAnalysis(newAnalysis), instrumentID: ticker) {
            case .success:
                break
            case .failure(let error):
                return .failure(error)
            }
            switch mapDataStoreResult(await dataStore.saveTrades(newTrades), instrumentID: ticker) {
            case .success:
                break
            case .failure(let error):
                return .failure(error)
            }
            if policy == .customStrategy {
                switch mapDataStoreResult(await dataStore.saveSimulationRules(finalRules), instrumentID: ticker) {
                case .success:
                    break
                case .failure(let error):
                    return .failure(error)
                }
            }
            switch mapDataStoreResult(await dataStore.saveRisks(newRisks), instrumentID: ticker) {
            case .success:
                break
            case .failure(let error):
                return .failure(error)
            }
        }

        return .success(BKSimulationInstrumentReport(
            instrumentID: ticker,
            elapsedMS: Date().timeIntervalSince(started) * 1000,
            configCountProcessed: configCountProcessed,
            tradeCount: tradeCount,
            riskPointCount: riskPointCount
        ))
    }

    private func mapFailure(instrumentID: String, error: Error) -> BKEngineFailure {
        BKErrorMapper.map(instrumentID: instrumentID, error: error)
    }

    private func mapDataStoreResult<T>(
        _ result: Result<T, Error>,
        instrumentID: String
    ) -> Result<T, BKEngineFailure> {
        result.mapError { mapFailure(instrumentID: instrumentID, error: $0) }
    }

    private func mapParsingResult<T>(
        _ result: Result<T, BKCSVParsingError>,
        instrumentID: String
    ) -> Result<T, BKEngineFailure> {
        result.mapError { mapFailure(instrumentID: instrumentID, error: $0) }
    }

    private func currentResidentMemoryBytes() -> UInt64? {
        #if canImport(Darwin)
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
        let result: kern_return_t = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), intPtr, &count)
            }
        }
        if result == KERN_SUCCESS {
            return UInt64(info.resident_size)
        }
        return nil
        #else
        return nil
        #endif
    }
}
