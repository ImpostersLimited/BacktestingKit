import XCTest
@testable import BacktestingKit

final class BacktestingKitAppFacadeTests: XCTestCase {
    private actor EmptyStore: BKV3DataStore {
        func getConfigs(instrumentID: String) async -> Result<[BKV3_Config], Error> { .success([]) }
        func getSimulationRules(configID: String, ruleType: String) async -> Result<[BKV3_SimulationRule], Error> { .success([]) }
        func saveConfig(_ config: BKV3_Config) async -> Result<Void, Error> { .success(()) }
        func saveAnalysis(_ analysis: BKV3_AnalysisProfile) async -> Result<Void, Error> { .success(()) }
        func saveTrades(_ trades: [BKV3_TradeEntry]) async -> Result<Void, Error> { .success(()) }
        func saveSimulationRules(_ rules: [BKV3_SimulationRule]) async -> Result<Void, Error> { .success(()) }
        func saveRisks(_ risks: [BKV3_RiskProfile]) async -> Result<Void, Error> { .success(()) }
    }

    private let inlineCsv = """
    timestamp,open,high,low,close,volume
    2024-01-01,10,11,9,10.5,100
    2024-01-02,10.5,11.5,10,11,120
    2024-01-03,11,12,10.8,11.8,140
    2024-01-04,11.8,12.2,11.3,12,130
    2024-01-05,12,12.4,11.9,12.2,125
    """

    private let mappedCsv = """
    trade_date,price_open,price_high,price_low,price_close,share_volume
    2024-02-01,20,21,19,20.5,200
    2024-02-02,20.5,21.5,20.1,21.2,240
    """

    private let shuffledMappedCsv = """
    price_open,trade_date,price_high,price_low,price_close,share_volume
    20,2024-02-01,21,19,20.5,200
    20.5,2024-02-02,21.5,20.1,21.2,240
    """

    private let descendingCsv = """
    timestamp,open,high,low,close,volume
    2024-01-05,12,12.4,11.9,12.2,125
    2024-01-04,11.8,12.2,11.3,12,130
    2024-01-03,11,12,10.8,11.8,140
    2024-01-02,10.5,11.5,10,11,120
    2024-01-01,10,11,9,10.5,100
    """

    private let ambiguousDateCsv = """
    timestamp,date,open,high,low,close,volume
    2024-03-01,2024-03-01,10,11,9,10.5,100
    2024-03-02,2024-03-02,10.5,11.2,10.1,10.9,110
    """

    func testAppFacadeRunPresetDelegatesToEngine() {
        let engine = BKEngine.runPreset(dataset: .aapl, preset: .smaCrossover)
        let facade = BKAppFacade.runPreset(dataset: .aapl, preset: .smaCrossover)

        switch (engine, facade) {
        case let (.success(lhs), .success(rhs)):
            XCTAssertEqual(lhs, rhs)
        default:
            XCTFail("Expected facade preset run to match engine preset run")
        }
    }

    func testAppFacadeRunPresetCSVAndExportMarkdownSuccess() {
        let report = BKAppFacade.runPresetCSVAndExportMarkdown(
            symbol: "AAPL",
            csv: inlineCsv,
            preset: .smaCrossover,
            title: "AAPL preset run"
        )

        XCTAssertTrue(report.isSuccessful)
        XCTAssertTrue(report.run.isSuccessful)
        XCTAssertNotNil(report.run.summary)
        XCTAssertTrue(report.markdown?.contains("# AAPL preset run") == true)
        XCTAssertNil(report.exportError)
    }

    func testAppFacadeRunPresetCSVAndExportMarkdownReturnsRunFailure() {
        let report = BKAppFacade.runPresetCSVAndExportMarkdown(
            symbol: "AAPL",
            csv: "",
            preset: .smaCrossover
        )

        XCTAssertFalse(report.isSuccessful)
        XCTAssertFalse(report.run.isSuccessful)
        XCTAssertNil(report.markdown)
        XCTAssertNil(report.exportError)
    }

    func testAppFacadeInspectCSVReturnsReadyReportForValidCsv() {
        let report = BKAppFacade.inspectCSV(symbol: "AAPL", csv: inlineCsv)

        XCTAssertTrue(report.isReady)
        XCTAssertEqual(report.symbol, "AAPL")
        XCTAssertEqual(report.preflight.rowCount, 5)
        XCTAssertEqual(report.errorCount, 0)
        XCTAssertEqual(report.warningCount, 0)
    }

    func testAppFacadeInspectCSVReturnsErrorForEmptyCsv() {
        let report = BKAppFacade.inspectCSV(symbol: "AAPL", csv: "")

        XCTAssertFalse(report.isReady)
        XCTAssertEqual(report.errorCount, 1)
        XCTAssertEqual(report.preflight.validation.issues.first?.code, "csv_empty")
    }

    func testDetectCSVImportSettingsInfersSafeSettingsForStandardCsv() {
        let report = BKAppFacade.detectCSVImportSettings(symbol: "AAPL", csv: inlineCsv)

        XCTAssertTrue(report.isFullyInferred)
        XCTAssertEqual(report.inferredSettings.columnMapping?.date, "timestamp")
        XCTAssertEqual(report.inferredSettings.columnMapping?.open, "open")
        XCTAssertEqual(report.inferredSettings.columnMapping?.volume, "volume")
        XCTAssertEqual(report.inferredSettings.dateFormat, "yyyy-MM-dd")
        XCTAssertEqual(report.inferredSettings.reverse, false)
        XCTAssertEqual(report.effectiveSettings.dateFormat, "yyyy-MM-dd")
        XCTAssertEqual(report.effectiveSettings.reverse, false)
    }

    func testDetectCSVImportSettingsInfersNonLeadingTradeDateColumn() {
        let report = BKAppFacade.detectCSVImportSettings(symbol: "MAPPED", csv: shuffledMappedCsv)

        XCTAssertTrue(report.isFullyInferred)
        XCTAssertEqual(report.inferredSettings.columnMapping?.date, "trade_date")
        XCTAssertEqual(report.inferredSettings.columnMapping?.open, "price_open")
        XCTAssertEqual(report.inferredSettings.columnMapping?.close, "price_close")
        XCTAssertEqual(report.inferredSettings.dateFormat, "yyyy-MM-dd")
        XCTAssertEqual(report.inferredSettings.reverse, false)
    }

    func testDetectCSVImportSettingsKeepsAmbiguousDateExplicit() {
        let report = BKAppFacade.detectCSVImportSettings(symbol: "AAPL", csv: ambiguousDateCsv)

        XCTAssertFalse(report.isFullyInferred)
        XCTAssertNil(report.inferredSettings.columnMapping)
        XCTAssertEqual(report.inferredSettings.dateFormat, "yyyy-MM-dd")
        XCTAssertEqual(report.inferredSettings.reverse, false)
        XCTAssertTrue(report.issues.contains(where: { $0.code == "csv_inference_ambiguous_date" }))
    }

    func testAppFacadePreviewCSVTruncatesRows() {
        let report = BKAppFacade.previewCSV(
            symbol: "AAPL",
            csv: inlineCsv,
            maxRows: 2
        )

        XCTAssertTrue(report.isSuccessful)
        XCTAssertEqual(report.rowCount, 5)
        XCTAssertEqual(report.rows.count, 2)
        XCTAssertEqual(report.rows.first?.open, 10)
        XCTAssertEqual(report.rows.last?.close, 11)
    }

    func testAppFacadePreviewCSVSupportsCustomColumnMapping() {
        let mapping = BKCSVColumnMapping(
            date: "trade_date",
            open: "price_open",
            high: "price_high",
            low: "price_low",
            close: "price_close",
            volume: "share_volume"
        )

        let report = BKAppFacade.previewCSV(
            symbol: "MAPPED",
            csv: mappedCsv,
            columnMapping: mapping,
            maxRows: 2
        )

        XCTAssertTrue(report.isSuccessful)
        XCTAssertEqual(report.rowCount, 2)
        XCTAssertEqual(report.rows.count, 2)
        XCTAssertEqual(report.rows.first?.close, 20.5)
        XCTAssertEqual(report.rows.last?.volume, 240)
    }

    func testAppFacadePreviewCSVAutoNormalizesDescendingInput() {
        let report = BKAppFacade.previewCSVAuto(
            symbol: "AAPL",
            csv: descendingCsv,
            maxRows: 2
        )

        XCTAssertEqual(report.inference.inferredSettings.reverse, true)
        XCTAssertEqual(report.inference.effectiveSettings.reverse, false)
        XCTAssertTrue(report.preview.isSuccessful)
        XCTAssertEqual(report.preview.rowCount, 5)
        XCTAssertEqual(report.preview.rows.count, 2)
        XCTAssertEqual(report.preview.rows.first?.close, 10.5)
        XCTAssertEqual(report.preview.rows.last?.close, 11)
    }

    func testAppFacadeValidateCSVImportReturnsParseFailure() {
        let invalidCsv = """
        timestamp,open,high,low,close,volume
        not-a-date,10,11,9,10.5,100
        """

        let report = BKAppFacade.validateCSVImport(symbol: "AAPL", csv: invalidCsv)

        XCTAssertFalse(report.isSuccessful)
        XCTAssertFalse(report.parseValidation.isValid)
        XCTAssertEqual(report.parseValidation.issues.first?.code, "csv_import_parse_error")
        XCTAssertNotNil(report.parseError)
    }

    func testAppFacadeNormalizeCSVImportReturnsBarsAndCandles() {
        let report = BKAppFacade.normalizeCSVImport(symbol: "AAPL", csv: inlineCsv)

        XCTAssertTrue(report.isSuccessful)
        XCTAssertEqual(report.rowCount, 5)
        XCTAssertEqual(report.bars.count, 5)
        XCTAssertEqual(report.candles.count, 5)
        XCTAssertEqual(report.bars.first?.open, 10)
        XCTAssertEqual(report.candles.last?.close, 12.2)
    }

    func testAppFacadeNormalizeCSVImportAutoUsesInferredSettings() {
        let report = BKAppFacade.normalizeCSVImportAuto(symbol: "MAPPED", csv: shuffledMappedCsv)

        XCTAssertTrue(report.normalization.isSuccessful)
        XCTAssertEqual(report.inference.inferredSettings.columnMapping?.date, "trade_date")
        XCTAssertEqual(report.normalization.rowCount, 2)
        XCTAssertEqual(report.normalization.bars.first?.open, 20)
        XCTAssertEqual(report.normalization.bars.last?.close, 21.2)
    }

    func testAppFacadeRunCSVImportReturnsStructuredSuccess() {
        let report = BKAppFacade.runCSVImport(
            symbol: "AAPL",
            csv: inlineCsv,
            preset: .smaCrossover
        )

        XCTAssertTrue(report.isSuccessful)
        XCTAssertEqual(report.symbol, "AAPL")
        XCTAssertEqual(report.preset, .smaCrossover)
        XCTAssertNotNil(report.normalization)
        XCTAssertTrue(report.normalization?.isSuccessful == true)
        XCTAssertTrue(report.run?.isSuccessful == true)
        XCTAssertEqual(report.summary?.symbol, "AAPL")
    }

    func testAppFacadeRunCSVImportReturnsStructuredFailure() {
        let report = BKAppFacade.runCSVImport(
            symbol: "AAPL",
            csv: "",
            preset: .smaCrossover
        )

        XCTAssertFalse(report.isSuccessful)
        XCTAssertNil(report.run)
        XCTAssertNil(report.summary)
        XCTAssertNotNil(report.failureDescription)
    }

    func testAppFacadeValidateCSVImportAutoKeepsAmbiguityVisible() {
        let report = BKAppFacade.validateCSVImportAuto(symbol: "AAPL", csv: ambiguousDateCsv)

        XCTAssertTrue(report.validation.isSuccessful)
        XCTAssertFalse(report.inference.isFullyInferred)
        XCTAssertTrue(report.inference.issues.contains(where: { $0.code == "csv_inference_ambiguous_date" }))
    }

    func testAppFacadeRunCSVImportAutoSucceedsForDescendingInput() {
        let report = BKAppFacade.runCSVImportAuto(
            symbol: "AAPL",
            csv: descendingCsv,
            preset: .smaCrossover
        )

        XCTAssertTrue(report.run.isSuccessful)
        XCTAssertEqual(report.inference.inferredSettings.reverse, true)
        XCTAssertEqual(report.run.summary?.symbol, "AAPL")
        XCTAssertEqual(report.run.normalization?.bars.first?.close, 10.5)
        XCTAssertEqual(report.run.normalization?.bars.last?.close, 12.2)
    }

    func testAppFacadeDiagnoseCSVImportReturnsDetailedSuccessReportForCleanCsv() {
        let report = BKAppFacade.diagnoseCSVImport(
            symbol: "AAPL",
            csv: inlineCsv,
            maxFailureRows: 3
        )

        XCTAssertEqual(report.symbol, "AAPL")
        XCTAssertNil(report.failureStage)
        XCTAssertTrue(report.isImportViable)
        XCTAssertTrue(report.rowFailures.isEmpty)
        XCTAssertNotNil(report.previewSummary)
        XCTAssertNotNil(report.normalizationSummary)
        XCTAssertEqual(report.stageDecisions.map(\.stage), [.inspection, .inference, .preview, .validation, .normalization])
        XCTAssertEqual(report.stageDecisions.map(\.outcome), [.success, .success, .success, .success, .success])
    }

    func testAppFacadeDiagnoseCSVImportKeepsAmbiguousInferenceVisible() {
        let report = BKAppFacade.diagnoseCSVImport(
            symbol: "AAPL",
            csv: ambiguousDateCsv
        )

        XCTAssertNil(report.failureStage)
        XCTAssertTrue(report.isImportViable)
        XCTAssertTrue(report.rowFailures.isEmpty)
        XCTAssertFalse(report.inference.isFullyInferred)
        XCTAssertTrue(report.inference.issues.contains(where: { $0.code == "csv_inference_ambiguous_date" }))
        XCTAssertEqual(report.stageDecisions.first(where: { $0.stage == .inference })?.outcome, .warning)
        XCTAssertEqual(report.stageDecisions.first(where: { $0.stage == .validation })?.outcome, .success)
        XCTAssertEqual(report.stageDecisions.first(where: { $0.stage == .normalization })?.outcome, .success)
    }

    func testAppFacadeDiagnoseCSVImportReturnsInvalidForEmptyCsv() {
        let report = BKAppFacade.diagnoseCSVImport(
            symbol: "AAPL",
            csv: ""
        )

        XCTAssertEqual(report.failureStage, .inspection)
        XCTAssertFalse(report.isImportViable)
        XCTAssertTrue(report.rowFailures.isEmpty)
        XCTAssertNil(report.previewSummary)
        XCTAssertNil(report.normalizationSummary)
        XCTAssertEqual(report.stageDecisions.first(where: { $0.stage == .inspection })?.outcome, .failed)
        XCTAssertEqual(report.stageDecisions.first(where: { $0.stage == .preview })?.outcome, .skipped)
        XCTAssertEqual(report.stageDecisions.first(where: { $0.stage == .validation })?.outcome, .skipped)
        XCTAssertEqual(report.stageDecisions.first(where: { $0.stage == .normalization })?.outcome, .skipped)
    }

    func testAppFacadeDiagnoseCSVImportReturnsInspectionFailureForMalformedRows() {
        let invalidCsv = """
        timestamp,open,high,low,close,volume
        2024-01-02,10,11,9,not-a-number,100
        """

        let report = BKAppFacade.diagnoseCSVImport(
            symbol: "AAPL",
            csv: invalidCsv,
            maxFailureRows: 5
        )

        XCTAssertEqual(report.failureStage, .inspection)
        XCTAssertFalse(report.isImportViable)
        XCTAssertEqual(report.stageDecisions.first(where: { $0.stage == .inspection })?.outcome, .failed)
        XCTAssertEqual(report.stageDecisions.first(where: { $0.stage == .preview })?.outcome, .skipped)
        XCTAssertEqual(report.stageDecisions.first(where: { $0.stage == .validation })?.outcome, .skipped)
        XCTAssertEqual(report.stageDecisions.first(where: { $0.stage == .normalization })?.outcome, .skipped)
        XCTAssertTrue(report.rowFailures.isEmpty)
    }

    func testBuildCSVImportScreenStateReturnsReadyStateForCleanCsv() {
        let state = BKAppFacade.buildCSVImportScreenState(
            symbol: "AAPL",
            csv: inlineCsv,
            maxRows: 2
        )

        XCTAssertEqual(state.status, .ready)
        XCTAssertTrue(state.isReadyToContinue)
        XCTAssertNotNil(state.preview)
        XCTAssertNotNil(state.validation)
        XCTAssertNotNil(state.normalization)
        XCTAssertEqual(state.preview?.preview.rows.count, 2)
        XCTAssertEqual(state.issues.map(\.title), ["Inspection", "Inference", "Validation"])
    }

    func testBuildCSVImportScreenStateReturnsNeedsReviewForAmbiguousInference() {
        let state = BKAppFacade.buildCSVImportScreenState(
            symbol: "AAPL",
            csv: ambiguousDateCsv,
            maxRows: 2
        )

        XCTAssertEqual(state.status, .needsReview)
        XCTAssertFalse(state.isReadyToContinue)
        XCTAssertNotNil(state.preview)
        XCTAssertNotNil(state.validation)
        XCTAssertNotNil(state.normalization)
        let inferenceSection = state.issues.first(where: { $0.title == "Inference" })
        XCTAssertTrue(inferenceSection?.items.contains(where: { $0.code == "csv_inference_ambiguous_date" }) == true)
    }

    func testBuildCSVImportScreenStateReturnsInvalidForEmptyCsv() {
        let state = BKAppFacade.buildCSVImportScreenState(
            symbol: "AAPL",
            csv: ""
        )

        XCTAssertEqual(state.status, .invalid)
        XCTAssertFalse(state.isReadyToContinue)
        XCTAssertNil(state.preview)
        XCTAssertNil(state.validation)
        XCTAssertNil(state.normalization)
        let inspectionSection = state.issues.first(where: { $0.title == "Inspection" })
        XCTAssertTrue(inspectionSection?.items.contains(where: { $0.code == "csv_empty" }) == true)
    }

    func testRunConfirmedCSVImportUsesReviewStateSettingsForDescendingCsv() {
        let screenState = BKAppFacade.buildCSVImportScreenState(
            symbol: "AAPL",
            csv: descendingCsv,
            maxRows: 2
        )

        let report = BKAppFacade.runConfirmedCSVImport(
            from: screenState,
            csv: descendingCsv,
            preset: .smaCrossover
        )

        XCTAssertTrue(report.run.isSuccessful)
        XCTAssertEqual(report.confirmedSettings.reverse, false)
        XCTAssertEqual(report.run.summary?.symbol, "AAPL")
        XCTAssertEqual(report.run.normalization?.bars.first?.close, 10.5)
        XCTAssertEqual(report.run.normalization?.bars.last?.close, 12.2)
    }

    func testRunConfirmedCSVImportAllowsExplicitConfirmedSettingsOverride() {
        let screenState = BKAppFacade.buildCSVImportScreenState(
            symbol: "AAPL",
            csv: ambiguousDateCsv,
            maxRows: 2
        )

        let mapping = BKCSVColumnMapping(
            date: "date",
            open: "open",
            high: "high",
            low: "low",
            close: "close",
            volume: "volume"
        )

        let report = BKAppFacade.runConfirmedCSVImport(
            from: screenState,
            csv: ambiguousDateCsv,
            preset: .smaCrossover,
            confirmedSettings: BKAppCSVConfirmedImportSettings(
                columnMapping: mapping,
                dateFormat: "yyyy-MM-dd",
                reverse: false
            )
        )

        XCTAssertTrue(report.run.isSuccessful)
        XCTAssertEqual(report.confirmedSettings.columnMapping?.date, "date")
        XCTAssertEqual(report.confirmedSettings.dateFormat, "yyyy-MM-dd")
        XCTAssertEqual(report.confirmedSettings.reverse, false)
        XCTAssertEqual(report.run.summary?.symbol, "AAPL")
    }

    func testBuildPortfolioCSVImportScreenStateReturnsReadyWhenAllSleevesAreReady() {
        let state = BKAppFacade.buildPortfolioCSVImportScreenState(
            portfolioID: "BASKET",
            sleeves: [
                BKAppPortfolioImportItem(symbol: "AAPL", csv: inlineCsv, preset: .smaCrossover, targetWeight: 0.6),
                BKAppPortfolioImportItem(symbol: "MSFT", csv: inlineCsv, preset: .emaCrossover, targetWeight: 0.4),
            ],
            allocation: .sleeveWeights,
            maxRows: 2
        )

        XCTAssertEqual(state.portfolioID, "BASKET")
        XCTAssertEqual(state.status, .ready)
        XCTAssertTrue(state.isReadyToContinue)
        XCTAssertEqual(state.sleeves.count, 2)
        XCTAssertEqual(state.sleeves.map(\.screenState.status), [.ready, .ready])
        XCTAssertEqual(state.allocation.mode, .sleeveWeights)
    }

    func testBuildPortfolioCSVImportScreenStateReturnsInvalidWhenAnySleeveIsInvalid() {
        let state = BKAppFacade.buildPortfolioCSVImportScreenState(
            sleeves: [
                BKAppPortfolioImportItem(symbol: "AAPL", csv: inlineCsv, preset: .smaCrossover),
                BKAppPortfolioImportItem(symbol: "BROKEN", csv: "", preset: .smaCrossover),
            ]
        )

        XCTAssertEqual(state.portfolioID, "PORTFOLIO")
        XCTAssertEqual(state.status, .invalid)
        XCTAssertFalse(state.isReadyToContinue)
        XCTAssertEqual(state.sleeves.count, 2)
        XCTAssertTrue(state.issues.contains(where: { $0.symbol == "BROKEN" }))
    }

    func testBuildPortfolioCSVImportScreenStateRejectsDuplicateSleeves() {
        let state = BKAppFacade.buildPortfolioCSVImportScreenState(
            portfolioID: "DUPES",
            sleeves: [
                BKAppPortfolioImportItem(symbol: "AAPL", csv: inlineCsv, preset: .smaCrossover),
                BKAppPortfolioImportItem(symbol: "AAPL", csv: inlineCsv, preset: .emaCrossover),
            ],
            allocation: .sleeveWeights,
            maxRows: 2
        )

        XCTAssertEqual(state.status, .invalid)
        XCTAssertFalse(state.isReadyToContinue)
        XCTAssertTrue(state.issues.contains(where: {
            $0.symbol == "DUPES"
                && $0.title == "Portfolio"
                && $0.items.contains(where: { $0.code == "portfolio_duplicate_symbols" })
        }))
    }

    func testBuildPortfolioCSVImportScreenStateRejectsExplicitWeightCountMismatch() {
        let state = BKAppFacade.buildPortfolioCSVImportScreenState(
            portfolioID: "MISMATCH",
            sleeves: [
                BKAppPortfolioImportItem(symbol: "AAPL", csv: inlineCsv, preset: .smaCrossover),
                BKAppPortfolioImportItem(symbol: "MSFT", csv: inlineCsv, preset: .emaCrossover),
            ],
            allocation: .explicit([1.0]),
            maxRows: 2
        )

        XCTAssertEqual(state.status, .invalid)
        XCTAssertFalse(state.isReadyToContinue)
        XCTAssertTrue(state.issues.contains(where: {
            $0.symbol == "MISMATCH"
                && $0.title == "Portfolio"
                && $0.items.contains(where: { $0.code == "portfolio_explicit_weight_count_mismatch" })
        }))
    }

    func testBuildPortfolioCSVImportScreenStateRejectsExplicitWeightTotalThatIsNotPositive() {
        let state = BKAppFacade.buildPortfolioCSVImportScreenState(
            portfolioID: "ZERO_TOTAL",
            sleeves: [
                BKAppPortfolioImportItem(symbol: "AAPL", csv: inlineCsv, preset: .smaCrossover),
                BKAppPortfolioImportItem(symbol: "MSFT", csv: inlineCsv, preset: .emaCrossover),
            ],
            allocation: .explicit([0, -1]),
            maxRows: 2
        )

        XCTAssertEqual(state.status, .invalid)
        XCTAssertFalse(state.isReadyToContinue)
        XCTAssertTrue(state.issues.contains(where: {
            $0.symbol == "ZERO_TOTAL"
                && $0.title == "Portfolio"
                && $0.items.contains(where: {
                    $0.code == "portfolio_explicit_weight_total_invalid"
                        && $0.message.localizedStandardContains("positive total")
                })
        }))
    }

    func testRunConfirmedPortfolioCSVImportUsesInferredSleeveSettings() {
        let screenState = BKAppFacade.buildPortfolioCSVImportScreenState(
            portfolioID: "AUTO",
            sleeves: [
                BKAppPortfolioImportItem(symbol: "AAPL", csv: descendingCsv, preset: .smaCrossover, targetWeight: 0.7),
                BKAppPortfolioImportItem(symbol: "MSFT", csv: inlineCsv, preset: .smaCrossover, targetWeight: 0.3),
            ],
            allocation: .sleeveWeights,
            maxRows: 2
        )

        let report = BKAppFacade.runConfirmedPortfolioCSVImport(from: screenState)

        XCTAssertTrue(report.run.isSuccessful)
        XCTAssertFalse(report.run.isPartialSuccess)
        XCTAssertEqual(report.confirmedSettingsBySymbol.count, 0)
        XCTAssertEqual(report.run.succeededSleeveCount, 2)
        XCTAssertEqual(report.run.failedSleeveCount, 0)
        XCTAssertEqual(report.run.sleeveReports.count, 2)
        XCTAssertEqual(report.run.sleeveReports[0].resolvedWeight, 0.7, accuracy: 1e-9)
        XCTAssertEqual(report.run.sleeveReports[1].resolvedWeight, 0.3, accuracy: 1e-9)
        XCTAssertEqual(
            report.run.sleeveReports.first?.summary?.startDate,
            ISO8601DateFormatter().date(from: "2024-01-01T00:00:00Z")
        )
    }

    func testRunConfirmedPortfolioCSVImportAllowsPerSleeveOverrides() {
        let screenState = BKAppFacade.buildPortfolioCSVImportScreenState(
            portfolioID: "OVERRIDES",
            sleeves: [
                BKAppPortfolioImportItem(symbol: "AAPL", csv: ambiguousDateCsv, preset: .smaCrossover),
                BKAppPortfolioImportItem(symbol: "MSFT", csv: inlineCsv, preset: .smaCrossover),
            ],
            allocation: .explicit([0.5, 0.5]),
            maxRows: 2
        )
        let mapping = BKCSVColumnMapping(
            date: "date",
            open: "open",
            high: "high",
            low: "low",
            close: "close",
            volume: "volume"
        )

        let report = BKAppFacade.runConfirmedPortfolioCSVImport(
            from: screenState,
            confirmedSettingsBySymbol: [
                "AAPL": BKAppCSVConfirmedImportSettings(
                    columnMapping: mapping,
                    dateFormat: "yyyy-MM-dd",
                    reverse: false
                )
            ]
        )

        XCTAssertTrue(report.run.isSuccessful)
        XCTAssertEqual(report.confirmedSettingsBySymbol["AAPL"]?.columnMapping?.date, "date")
        XCTAssertEqual(report.run.succeededSleeveCount, 2)
        XCTAssertEqual(report.run.sleeveReports.count, 2)
        XCTAssertEqual(report.run.sleeveReports[0].resolvedWeight, 0.5, accuracy: 1e-9)
        XCTAssertEqual(report.run.sleeveReports[1].resolvedWeight, 0.5, accuracy: 1e-9)
    }

    func testAppFacadeRunCSVImportAndExportMarkdownSuccess() {
        let report = BKAppFacade.runCSVImportAndExportMarkdown(
            symbol: "AAPL",
            csv: inlineCsv,
            preset: .smaCrossover,
            title: "Imported CSV run"
        )

        XCTAssertTrue(report.isSuccessful)
        XCTAssertTrue(report.run.isSuccessful)
        XCTAssertTrue(report.markdown?.contains("# Imported CSV run") == true)
        XCTAssertNil(report.exportError)
    }

    func testAppFacadeRunCSVImportAutoAndExportMarkdownSuccess() {
        let report = BKAppFacade.runCSVImportAutoAndExportMarkdown(
            symbol: "AAPL",
            csv: descendingCsv,
            preset: .smaCrossover,
            title: "Auto imported CSV run"
        )

        XCTAssertTrue(report.run.isSuccessful)
        XCTAssertTrue(report.run.markdown?.contains("# Auto imported CSV run") == true)
        XCTAssertEqual(report.inference.inferredSettings.reverse, true)
    }

    func testAppFacadeRunScenarioAndExportBundleSuccess() {
        let config = BKScenarioConfig(symbol: "SCENARIO", barCount: 20, seed: 5, strategy: .smaCrossover)
        let report = BKAppFacade.runScenarioAndExportBundle(config: config)

        XCTAssertTrue(report.isSuccessful)
        XCTAssertEqual(report.config, config)
        XCTAssertEqual(report.summary.symbol, "SCENARIO")
        XCTAssertTrue(report.exportBundle?.summaryJSON.contains("\"symbol\"") == true)
        XCTAssertTrue(report.exportBundle?.scenarioJSON?.contains("\"strategy\"") == true)
        XCTAssertNil(report.exportError)
    }

    func testAppFacadeCompareAndAssertEquivalentDelegateToComparisonTool() throws {
        let baseline = BKRunSummary(
            symbol: "AAPL",
            barCount: 5,
            metrics: BKRunHeadlineMetrics(
                tradeCount: 1,
                winRate: 1.0,
                totalReturn: 0.1,
                annualizedReturn: 0.08,
                maxDrawdown: 0.02,
                sharpeRatio: 1.2,
                profitFactor: 2.0
            )
        )
        let candidate = baseline

        let report = BKAppFacade.compareRuns(baseline: baseline, candidate: candidate)
        XCTAssertTrue(report.isEquivalent)

        let assertion = try BKAppFacade.assertEquivalent(baseline: baseline, candidate: candidate)
        XCTAssertEqual(assertion, report)
    }

    func testAppFacadeRunV2ValidatedCSVDelegatesToEngine() async {
        var config = BKV2.SimulationPolicyConfig()
        config.policy = .sma
        config.entryRules = []
        config.exitRules = []

        let report = await BKAppFacade.runV2ValidatedCSV(
            instrumentID: "AAPL",
            config: config,
            csv: inlineCsv
        )

        XCTAssertTrue(report.preflight.isReady)
        XCTAssertTrue(report.requestValidation.isValid)
        XCTAssertTrue(report.isSuccessful)
        XCTAssertNotNil(report.output)
        XCTAssertNotNil(report.positionStatus)
    }

    func testAppFacadeRunV3ValidatedCSVDelegatesToEngine() async {
        let instrument = BKV3_InstrumentInfo(id: "AAPL", name: nil, exchange: nil, quoteType: nil, createdAt: nil, lastUpdated: nil)

        let report = await BKAppFacade.runV3ValidatedCSV(
            instrument: instrument,
            dataStore: EmptyStore(),
            csv: inlineCsv
        )

        XCTAssertTrue(report.preflight.isReady)
        XCTAssertTrue(report.requestValidation.isValid)
        XCTAssertTrue(report.isSuccessful)
        XCTAssertEqual(report.report?.instrumentID, "AAPL")
    }
}
