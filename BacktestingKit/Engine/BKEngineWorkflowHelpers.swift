import Foundation

public extension BKEngine {
    /// Runs a bundled dataset through a preset-backed workflow from the engine surface.
    static func runPreset(
        dataset: BKQuickDemoDataset,
        preset: BKPresetCatalog,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> Result<BKRunSummary, Error> {
        BKQuickDemo.runBundledPresetDemo(dataset: dataset, preset: preset, log: log)
    }

    /// Runs inline CSV through a preset-backed workflow and returns a compact summary.
    static func runPresetCSV(
        symbol: String,
        csv: String,
        preset: BKPresetCatalog,
        dateFormat: String = "yyyy-MM-dd",
        reverse: Bool = false,
        columnMapping: BKCSVColumnMapping? = nil,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> Result<BKRunSummary, Error> {
        log("[Engine] Starting preset CSV run for \(symbol) with \(preset.displayName).")

        let bars: [BKBar]
        switch BKQuickDemo.parseBars(
            csv: csv,
            dateFormat: dateFormat,
            reverse: reverse,
            columnMapping: columnMapping
        ) {
        case .success(let parsed):
            bars = parsed
        case .failure(let error):
            return .failure(error)
        }

        let candles = BKQuickDemo.makeCandles(from: bars)
        return BKQuickDemo.runPresetSummary(symbol: symbol, bars: bars, candles: candles, preset: preset)
    }

    /// Runs CSV preflight and preset execution in one bundled helper.
    static func preflightAndRunCSV(
        symbol: String,
        csv: String,
        preset: BKPresetCatalog = .smaCrossover,
        dateFormat: String = "yyyy-MM-dd",
        reverse: Bool = false,
        columnMapping: BKCSVColumnMapping? = nil,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> BKPreflightedRunSummary {
        let preflight = BKValidationTool.preflightCSV(csv, symbol: symbol, columnMapping: columnMapping)
        guard preflight.isReady else {
            return BKPreflightedRunSummary(
                symbol: symbol,
                preset: preset,
                preflight: preflight,
                failure: makeHelperValidationFailure(
                    instrumentID: symbol,
                    stage: "csv-preflight",
                    validation: preflight.validation
                ),
                isSuccessful: false
            )
        }

        switch runPresetCSV(
            symbol: symbol,
            csv: csv,
            preset: preset,
            dateFormat: dateFormat,
            reverse: reverse,
            columnMapping: columnMapping,
            log: log
        ) {
        case .success(let summary):
            return BKPreflightedRunSummary(
                symbol: symbol,
                preset: preset,
                preflight: preflight,
                summary: summary,
                isSuccessful: true
            )
        case .failure(let error):
            return BKPreflightedRunSummary(
                symbol: symbol,
                preset: preset,
                preflight: preflight,
                failure: makeHelperFailure(
                    instrumentID: symbol,
                    stage: "preset-run",
                    error: error
                ),
                isSuccessful: false
            )
        }
    }

    /// Runs a deterministic scenario and returns a compact app-facing summary.
    static func runScenario(config: BKScenarioConfig) -> BKRunSummary {
        BKScenarioTool.summarize(config: config)
    }

    /// Builds a presentation-friendly run summary from parsed bars and a backtest result.
    static func summarize(
        symbol: String,
        bars: [BKBar],
        result: BacktestResult
    ) -> BKRunSummary {
        BKRunSummary(
            symbol: symbol,
            barCount: bars.count,
            startDate: bars.first?.time,
            endDate: bars.last?.time,
            metrics: BKRunHeadlineMetrics(result: result)
        )
    }

    /// Builds a presentation-friendly run summary from candles and a backtest result.
    static func summarize(
        symbol: String,
        candles: [Candlestick],
        result: BacktestResult
    ) -> BKRunSummary {
        BKRunSummary(
            symbol: symbol,
            barCount: candles.count,
            startDate: candles.first?.date,
            endDate: candles.last?.date,
            metrics: BKRunHeadlineMetrics(result: result)
        )
    }

    /// Runs a basic SMA crossover workflow directly from inline CSV.
    static func runDemoCSV(
        symbol: String,
        csv: String,
        fast: Int = 5,
        slow: Int = 20,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> Result<BKQuickDemoSummary, Error> {
        BKQuickDemo.runSMACrossoverDemo(
            symbol: symbol,
            csv: csv,
            fast: fast,
            slow: slow,
            log: log
        )
    }

    /// Runs a v2 request directly from inline CSV without requiring a provider implementation.
    static func runV2CSV(
        instrumentID: String,
        config: BKV2.SimulationPolicyConfig,
        csv: String,
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        csvColumnMapping: BKCSVColumnMapping? = nil,
        log: (@Sendable (String) -> Void)? = nil
    ) async -> Result<(BKV2.SimulateConfigOutput, PositionStatus), BKEngineFailure> {
        await runV2(
            .init(
                instrumentID: instrumentID,
                config: config,
                p1: p1,
                p2: p2,
                dateFormat: dateFormat,
                csvColumnMapping: csvColumnMapping,
                csvProvider: BKInlineCsvProvider(csv: csv),
                log: log
            )
        )
    }

    /// Runs CSV preflight, request validation, and v2 execution in one bundled helper.
    static func runV2ValidatedCSV(
        instrumentID: String,
        config: BKV2.SimulationPolicyConfig,
        csv: String,
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        csvColumnMapping: BKCSVColumnMapping? = nil,
        log: (@Sendable (String) -> Void)? = nil
    ) async -> BKV2ValidatedRunReport {
        let preflight = BKValidationTool.preflightCSV(csv, symbol: instrumentID, columnMapping: csvColumnMapping)
        let request = V2Request(
            instrumentID: instrumentID,
            config: config,
            p1: p1,
            p2: p2,
            dateFormat: dateFormat,
            csvColumnMapping: csvColumnMapping,
            csvProvider: BKInlineCsvProvider(csv: csv),
            log: log
        )
        let requestValidation = BKValidationTool.validateV2Request(request)

        if !preflight.isReady {
            return BKV2ValidatedRunReport(
                instrumentID: instrumentID,
                preflight: preflight,
                requestValidation: requestValidation,
                failure: makeHelperValidationFailure(
                    instrumentID: instrumentID,
                    stage: "csv-preflight",
                    validation: preflight.validation
                ),
                isSuccessful: false
            )
        }

        if !requestValidation.isValid {
            return BKV2ValidatedRunReport(
                instrumentID: instrumentID,
                preflight: preflight,
                requestValidation: requestValidation,
                failure: makeHelperValidationFailure(
                    instrumentID: instrumentID,
                    stage: "request-validation",
                    validation: requestValidation
                ),
                isSuccessful: false
            )
        }

        switch await runV2CSV(
            instrumentID: instrumentID,
            config: config,
            csv: csv,
            p1: p1,
            p2: p2,
            dateFormat: dateFormat,
            csvColumnMapping: csvColumnMapping,
            log: log
        ) {
        case .success(let payload):
            return BKV2ValidatedRunReport(
                instrumentID: instrumentID,
                preflight: preflight,
                requestValidation: requestValidation,
                output: payload.0,
                positionStatus: payload.1,
                isSuccessful: true
            )
        case .failure(let failure):
            return BKV2ValidatedRunReport(
                instrumentID: instrumentID,
                preflight: preflight,
                requestValidation: requestValidation,
                failure: failure,
                isSuccessful: false
            )
        }
    }

    /// Runs a v3 request directly from inline CSV without requiring a provider implementation.
    static func runV3CSV(
        instrument: BKV3_InstrumentInfo,
        dataStore: BKV3DataStore,
        csv: String,
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        executionOptions: BKSimulationExecutionOptions = BKSimulationExecutionOptions(),
        log: (@Sendable (String) -> Void)? = nil
    ) async -> Result<BKSimulationInstrumentReport, BKEngineFailure> {
        await runV3(
            .init(
                instrument: instrument,
                p1: p1,
                p2: p2,
                dateFormat: dateFormat,
                executionOptions: executionOptions,
                dataStore: dataStore,
                csvProvider: BKInlineCsvProvider(csv: csv),
                log: log
            )
        )
    }

    /// Runs CSV preflight, request validation, and v3 execution in one bundled helper.
    static func runV3ValidatedCSV(
        instrument: BKV3_InstrumentInfo,
        dataStore: BKV3DataStore,
        csv: String,
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        executionOptions: BKSimulationExecutionOptions = BKSimulationExecutionOptions(),
        log: (@Sendable (String) -> Void)? = nil
    ) async -> BKV3ValidatedRunReport {
        let preflight = BKValidationTool.preflightCSV(csv, symbol: instrument.id)
        let request = V3Request(
            instrument: instrument,
            p1: p1,
            p2: p2,
            dateFormat: dateFormat,
            executionOptions: executionOptions,
            dataStore: dataStore,
            csvProvider: BKInlineCsvProvider(csv: csv),
            log: log
        )
        let requestValidation = BKValidationTool.validateV3Request(request)

        if !preflight.isReady {
            return BKV3ValidatedRunReport(
                instrumentID: instrument.id,
                preflight: preflight,
                requestValidation: requestValidation,
                failure: makeHelperValidationFailure(
                    instrumentID: instrument.id,
                    stage: "csv-preflight",
                    validation: preflight.validation
                ),
                isSuccessful: false
            )
        }

        if !requestValidation.isValid {
            return BKV3ValidatedRunReport(
                instrumentID: instrument.id,
                preflight: preflight,
                requestValidation: requestValidation,
                failure: makeHelperValidationFailure(
                    instrumentID: instrument.id,
                    stage: "request-validation",
                    validation: requestValidation
                ),
                isSuccessful: false
            )
        }

        switch await runV3CSV(
            instrument: instrument,
            dataStore: dataStore,
            csv: csv,
            p1: p1,
            p2: p2,
            dateFormat: dateFormat,
            executionOptions: executionOptions,
            log: log
        ) {
        case .success(let report):
            return BKV3ValidatedRunReport(
                instrumentID: instrument.id,
                preflight: preflight,
                requestValidation: requestValidation,
                report: report,
                isSuccessful: true
            )
        case .failure(let failure):
            return BKV3ValidatedRunReport(
                instrumentID: instrument.id,
                preflight: preflight,
                requestValidation: requestValidation,
                failure: failure,
                isSuccessful: false
            )
        }
    }
}

public extension BKEngineOneLiner {
    /// Runs a v2 request directly from inline CSV without requiring a provider implementation.
    static func runBKV2CSV(
        instrumentID: String,
        config: BKV2.SimulationPolicyConfig,
        csv: String,
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        csvColumnMapping: BKCSVColumnMapping? = nil,
        log: (@Sendable (String) -> Void)? = nil
    ) async -> Result<(BKV2.SimulateConfigOutput, PositionStatus), BKEngineFailure> {
        await BKEngine.runV2CSV(
            instrumentID: instrumentID,
            config: config,
            csv: csv,
            p1: p1,
            p2: p2,
            dateFormat: dateFormat,
            csvColumnMapping: csvColumnMapping,
            log: log
        )
    }

    /// Runs a v3 request directly from inline CSV without requiring a provider implementation.
    static func runBKV3CSV(
        instrument: BKV3_InstrumentInfo,
        dataStore: BKV3DataStore,
        csv: String,
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        executionOptions: BKSimulationExecutionOptions = BKSimulationExecutionOptions(),
        log: (@Sendable (String) -> Void)? = nil
    ) async -> Result<BKSimulationInstrumentReport, BKEngineFailure> {
        await BKEngine.runV3CSV(
            instrument: instrument,
            dataStore: dataStore,
            csv: csv,
            p1: p1,
            p2: p2,
            dateFormat: dateFormat,
            executionOptions: executionOptions,
            log: log
        )
    }
}

private func makeHelperValidationFailure(
    instrumentID: String,
    stage: String,
    validation: BKValidationReport
) -> BKEngineFailure {
    let issue = validation.issues.first(where: { $0.severity == .error }) ?? validation.issues.first
    let message = issue?.message ?? "Validation failed."
    let code: BKEngineErrorCode

    switch issue?.code {
    case "csv_parse_error":
        code = .dataParsing
    default:
        code = .invalidInput
    }

    return BKEngineFailure(
        instrumentID: instrumentID,
        code: code,
        stage: stage,
        message: message,
        metadata: issue.map { ["issueCode": $0.code, "field": $0.field] } ?? [:]
    )
}

private func makeHelperFailure(
    instrumentID: String,
    stage: String,
    error: Error
) -> BKEngineFailure {
    if let failure = error as? BKEngineFailure {
        return failure
    }

    let code: BKEngineErrorCode
    switch error {
    case is BKCSVParsingError:
        code = .dataParsing
    case is BKQuickDemoError:
        code = .invalidInput
    default:
        code = .unknown
    }

    let message = error.localizedDescription.isEmpty ? String(describing: error) : error.localizedDescription
    return BKEngineFailure(
        instrumentID: instrumentID,
        code: code,
        stage: stage,
        message: message
    )
}
