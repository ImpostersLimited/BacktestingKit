import Foundation

/// App-facing facade for beginner and integration workflows.
///
/// `BKAppFacade` keeps the shortest-path APIs in one place while delegating to the canonical
/// engine and tool helpers. Use it when you want app-ready convenience without dropping into
/// request models or manager-owned composition surfaces.
public enum BKAppFacade {
    /// Runs a bundled dataset through a preset-backed workflow.
    public static func runPreset(
        dataset: BKQuickDemoDataset,
        preset: BKPresetCatalog,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> Result<BKRunSummary, Error> {
        BKEngine.runPreset(dataset: dataset, preset: preset, log: log)
    }

    /// Runs inline CSV through a preset-backed workflow and returns a compact summary.
    public static func runPresetCSV(
        symbol: String,
        csv: String,
        preset: BKPresetCatalog,
        dateFormat: String = "yyyy-MM-dd",
        reverse: Bool = false,
        columnMapping: BKCSVColumnMapping? = nil,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> Result<BKRunSummary, Error> {
        BKEngine.runPresetCSV(
            symbol: symbol,
            csv: csv,
            preset: preset,
            dateFormat: dateFormat,
            reverse: reverse,
            columnMapping: columnMapping,
            log: log
        )
    }

    /// Runs CSV preflight and preset execution in one bundled helper.
    public static func preflightAndRunCSV(
        symbol: String,
        csv: String,
        preset: BKPresetCatalog = .smaCrossover,
        dateFormat: String = "yyyy-MM-dd",
        reverse: Bool = false,
        columnMapping: BKCSVColumnMapping? = nil,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> BKPreflightedRunSummary {
        BKEngine.preflightAndRunCSV(
            symbol: symbol,
            csv: csv,
            preset: preset,
            dateFormat: dateFormat,
            reverse: reverse,
            columnMapping: columnMapping,
            log: log
        )
    }

    /// Inspects pasted CSV and returns structural readiness metadata for app-side import flows.
    public static func inspectCSV(
        symbol: String,
        csv: String,
        columnMapping: BKCSVColumnMapping? = nil
    ) -> BKAppCSVInspectionReport {
        let preflight = BKValidationTool.preflightCSV(csv, symbol: symbol, columnMapping: columnMapping)
        let issues = preflight.validation.issues
        let warningCount = issues.filter { $0.severity == .warning }.count
        let errorCount = issues.filter { $0.severity == .error }.count

        return BKAppCSVInspectionReport(
            symbol: symbol,
            columnMapping: columnMapping,
            preflight: preflight,
            issueCount: issues.count,
            warningCount: warningCount,
            errorCount: errorCount,
            isReady: preflight.isReady
        )
    }

    /// Detects safe CSV import settings and reports the effective settings the auto helpers will use.
    public static func detectCSVImportSettings(
        symbol: String,
        csv: String
    ) -> BKAppCSVInferenceReport {
        let inspection = inspectCSV(symbol: symbol, csv: csv)
        let detection = detectAutoCSVInference(csv: csv)

        return BKAppCSVInferenceReport(
            symbol: symbol,
            inspection: inspection,
            inferredSettings: detection.inferredSettings,
            effectiveSettings: detection.effectiveSettings,
            issues: detection.issues,
            isFullyInferred: detection.isFullyInferred
        )
    }

    /// Parses CSV into a bounded set of preview rows for app-side inspection UIs.
    public static func previewCSV(
        symbol: String,
        csv: String,
        dateFormat: String = "yyyy-MM-dd",
        reverse: Bool = false,
        columnMapping: BKCSVColumnMapping? = nil,
        maxRows: Int = 5
    ) -> BKAppCSVPreviewReport {
        let inspection = inspectCSV(symbol: symbol, csv: csv, columnMapping: columnMapping)
        let rowLimit = max(0, maxRows)

        switch parseImportBars(
            csv: csv,
            dateFormat: dateFormat,
            reverse: reverse,
            columnMapping: columnMapping
        ) {
        case .success(let bars):
            let previewRows = Array(bars.prefix(rowLimit)).map(makePreviewRow)
            return BKAppCSVPreviewReport(
                symbol: symbol,
                dateFormat: dateFormat,
                reverse: reverse,
                rowLimit: rowLimit,
                inspection: inspection,
                rowCount: bars.count,
                startDate: bars.first?.time,
                endDate: bars.last?.time,
                rows: previewRows,
                isSuccessful: true
            )
        case .failure(let error):
            return BKAppCSVPreviewReport(
                symbol: symbol,
                dateFormat: dateFormat,
                reverse: reverse,
                rowLimit: rowLimit,
                inspection: inspection,
                parseError: describe(error),
                isSuccessful: false
            )
        }
    }

    /// Detects CSV import settings, applies safe defaults, and returns a bounded preview.
    public static func previewCSVAuto(
        symbol: String,
        csv: String,
        maxRows: Int = 5
    ) -> BKAppCSVAutoPreviewReport {
        let inference = detectCSVImportSettings(symbol: symbol, csv: csv)
        let effectiveCSV = autoPreparedCSV(csv: csv, inference: inference)
        let preview = previewCSV(
            symbol: symbol,
            csv: effectiveCSV,
            dateFormat: inference.effectiveSettings.dateFormat,
            reverse: inference.effectiveSettings.reverse,
            columnMapping: inference.effectiveSettings.columnMapping,
            maxRows: maxRows
        )

        return BKAppCSVAutoPreviewReport(
            inference: inference,
            preview: preview
        )
    }

    /// Combines structural CSV preflight and parse-stage validation into one app-facing report.
    public static func validateCSVImport(
        symbol: String,
        csv: String,
        dateFormat: String = "yyyy-MM-dd",
        reverse: Bool = false,
        columnMapping: BKCSVColumnMapping? = nil
    ) -> BKAppCSVValidationReport {
        let inspection = inspectCSV(symbol: symbol, csv: csv, columnMapping: columnMapping)

        switch parseImportBars(
            csv: csv,
            dateFormat: dateFormat,
            reverse: reverse,
            columnMapping: columnMapping
        ) {
        case .success(let bars):
            let parseValidation = BKValidationReport(
                isValid: true,
                issues: [
                    BKValidationIssue(
                        code: "csv_import_parse_ok",
                        field: "csv",
                        message: "CSV import settings parsed successfully (\(bars.count) rows).",
                        severity: .info,
                        metadata: ["rowCount": String(bars.count)]
                    )
                ]
            )
            return BKAppCSVValidationReport(
                symbol: symbol,
                inspection: inspection,
                parseValidation: parseValidation,
                isSuccessful: inspection.isReady && parseValidation.isValid
            )
        case .failure(let error):
            let parseError = describe(error)
            let parseValidation = BKValidationReport(
                isValid: false,
                issues: [
                    BKValidationIssue(
                        code: "csv_import_parse_error",
                        field: "csv",
                        message: parseError,
                        severity: .error
                    )
                ]
            )
            return BKAppCSVValidationReport(
                symbol: symbol,
                inspection: inspection,
                parseValidation: parseValidation,
                parseError: parseError,
                isSuccessful: false
            )
        }
    }

    /// Detects CSV import settings, applies safe defaults, and returns a validation report.
    public static func validateCSVImportAuto(
        symbol: String,
        csv: String
    ) -> BKAppCSVAutoValidationReport {
        let inference = detectCSVImportSettings(symbol: symbol, csv: csv)
        let effectiveCSV = autoPreparedCSV(csv: csv, inference: inference)
        let validation = validateCSVImport(
            symbol: symbol,
            csv: effectiveCSV,
            dateFormat: inference.effectiveSettings.dateFormat,
            reverse: inference.effectiveSettings.reverse,
            columnMapping: inference.effectiveSettings.columnMapping
        )

        return BKAppCSVAutoValidationReport(
            inference: inference,
            validation: validation
        )
    }

    /// Parses CSV into normalized bars and candles for app-side import flows.
    public static func normalizeCSVImport(
        symbol: String,
        csv: String,
        dateFormat: String = "yyyy-MM-dd",
        reverse: Bool = false,
        columnMapping: BKCSVColumnMapping? = nil
    ) -> BKAppCSVNormalizedReport {
        let validation = validateCSVImport(
            symbol: symbol,
            csv: csv,
            dateFormat: dateFormat,
            reverse: reverse,
            columnMapping: columnMapping
        )

        switch parseImportBars(
            csv: csv,
            dateFormat: dateFormat,
            reverse: reverse,
            columnMapping: columnMapping
        ) {
        case .success(let bars):
            let candles = BKQuickDemo.makeCandles(from: bars)
            return BKAppCSVNormalizedReport(
                symbol: symbol,
                validation: validation,
                bars: bars,
                candles: candles,
                rowCount: bars.count,
                startDate: bars.first?.time,
                endDate: bars.last?.time,
                isSuccessful: validation.isSuccessful
            )
        case .failure(let error):
            return BKAppCSVNormalizedReport(
                symbol: symbol,
                validation: validation,
                parseError: describe(error),
                isSuccessful: false
            )
        }
    }

    /// Detects CSV import settings, applies safe defaults, and returns normalized bars/candles.
    public static func normalizeCSVImportAuto(
        symbol: String,
        csv: String
    ) -> BKAppCSVAutoNormalizedReport {
        let inference = detectCSVImportSettings(symbol: symbol, csv: csv)
        let effectiveCSV = autoPreparedCSV(csv: csv, inference: inference)
        let normalization = normalizeCSVImport(
            symbol: symbol,
            csv: effectiveCSV,
            dateFormat: inference.effectiveSettings.dateFormat,
            reverse: inference.effectiveSettings.reverse,
            columnMapping: inference.effectiveSettings.columnMapping
        )

        return BKAppCSVAutoNormalizedReport(
            inference: inference,
            normalization: normalization
        )
    }

    /// Diagnoses an app-side CSV import flow without mutating any import state.
    public static func diagnoseCSVImport(
        symbol: String,
        csv: String,
        maxFailureRows: Int = 5
    ) -> BKAppCSVImportDiagnosticsReport {
        let normalizedMaxFailureRows = max(0, maxFailureRows)
        let inspection = inspectCSV(symbol: symbol, csv: csv)
        let inference = detectCSVImportSettings(symbol: symbol, csv: csv)
        let preparedCSV = autoPreparedCSV(csv: csv, inference: inference)

        var stageDecisions: [BKAppCSVImportStageDecision] = []
        var failureStage: BKAppCSVImportFailureStage?

        let inspectionOutcome = diagnosticInspectionOutcome(for: inspection)
        stageDecisions.append(
            BKAppCSVImportStageDecision(
                stage: .inspection,
                outcome: inspectionOutcome,
                message: diagnosticInspectionMessage(for: inspection)
            )
        )
        if failureStage == nil, inspectionOutcome == .failed {
            failureStage = .inspection
        }

        let inferenceOutcome = diagnosticInferenceOutcome(for: inference)
        stageDecisions.append(
            BKAppCSVImportStageDecision(
                stage: .inference,
                outcome: inferenceOutcome,
                message: diagnosticInferenceMessage(for: inference)
            )
        )
        if failureStage == nil, inferenceOutcome == .failed {
            failureStage = .inference
        }

        var currentStage: BKAppCSVImportDiagnosticStage = .preview
        var preview: BKAppCSVAutoPreviewReport?
        var validation: BKAppCSVAutoValidationReport?
        var normalization: BKAppCSVAutoNormalizedReport?
        do {
            currentStage = .preview
            let canAttemptPreview = diagnosticShouldAttemptPreview(with: inspection, csv: csv)
            if canAttemptPreview {
                let report = try diagnosticAttemptPreview(symbol: symbol, csv: csv)
                preview = report
                let previewOutcome = diagnosticPreviewOutcome(
                    preview: report,
                    canAttempt: canAttemptPreview,
                    inspection: inspection
                )
                let previewMessage = diagnosticPreviewMessage(
                    canAttempt: canAttemptPreview,
                    preview: report,
                    inspection: inspection
                )
                stageDecisions.append(
                    BKAppCSVImportStageDecision(
                        stage: .preview,
                        outcome: previewOutcome,
                        message: previewMessage
                    )
                )
                if failureStage == nil, previewOutcome == .failed {
                    failureStage = .preview
                }
            } else {
                preview = nil
                stageDecisions.append(
                    BKAppCSVImportStageDecision(
                        stage: .preview,
                        outcome: .skipped,
                        message: diagnosticPreviewSkippedMessage(inspection: inspection)
                    )
                )
            }

            currentStage = .validation
            let canAttemptValidation = diagnosticShouldAttemptValidation(preview: preview)
            if canAttemptValidation {
                let report = try diagnosticAttemptValidation(symbol: symbol, csv: csv)
                validation = report
                let validationOutcome = diagnosticValidationOutcome(
                    validation: report,
                    canAttempt: canAttemptValidation
                )
                let validationMessage = diagnosticValidationMessage(
                    canAttempt: canAttemptValidation,
                    validation: report
                )
                stageDecisions.append(
                    BKAppCSVImportStageDecision(
                        stage: .validation,
                        outcome: validationOutcome,
                        message: validationMessage
                    )
                )
                if failureStage == nil, validationOutcome == .failed {
                    failureStage = .validation
                }
            } else {
                validation = nil
                stageDecisions.append(
                    BKAppCSVImportStageDecision(
                        stage: .validation,
                        outcome: .skipped,
                        message: diagnosticValidationSkippedMessage(preview: preview)
                    )
                )
            }

            currentStage = .normalization
            let canAttemptNormalization = diagnosticShouldAttemptNormalization(validation: validation)
            if canAttemptNormalization {
                let report = try diagnosticAttemptNormalization(symbol: symbol, csv: csv)
                normalization = report
                let normalizationOutcome = diagnosticNormalizationOutcome(
                    normalization: report,
                    canAttempt: canAttemptNormalization
                )
                let normalizationMessage = diagnosticNormalizationMessage(
                    canAttempt: canAttemptNormalization,
                    normalization: report
                )
                stageDecisions.append(
                    BKAppCSVImportStageDecision(
                        stage: .normalization,
                        outcome: normalizationOutcome,
                        message: normalizationMessage
                    )
                )
                if failureStage == nil, normalizationOutcome == .failed {
                    failureStage = .normalization
                }
            } else {
                normalization = nil
                stageDecisions.append(
                    BKAppCSVImportStageDecision(
                        stage: .normalization,
                        outcome: .skipped,
                        message: diagnosticNormalizationSkippedMessage(validation: validation)
                    )
                )
            }
        } catch {
            let failedStage = currentStage
            stageDecisions.append(
                BKAppCSVImportStageDecision(
                    stage: failedStage,
                    outcome: .failed,
                    message: diagnosticUnexpectedFailureMessage(stage: failedStage, error: error)
                )
            )
            if failureStage == nil {
                failureStage = BKAppCSVImportFailureStage(rawValue: failedStage.rawValue)
            }
            diagnosticAppendSkippedDecisions(
                after: failedStage,
                inspection: inspection,
                preview: preview,
                validation: validation,
                stageDecisions: &stageDecisions
            )
        }

        let previewSummary = preview.flatMap { report -> BKAppCSVPreviewSummary? in
            guard report.preview.isSuccessful else { return nil }
            return BKAppCSVPreviewSummary(
                rowCount: report.preview.rowCount,
                startDate: report.preview.startDate,
                endDate: report.preview.endDate,
                effectiveSettings: inference.effectiveSettings
            )
        }
        let normalizationSummary = normalization.flatMap { report -> BKAppCSVNormalizationSummary? in
            guard report.normalization.isSuccessful else { return nil }
            return BKAppCSVNormalizationSummary(
                rowCount: report.normalization.rowCount,
                startDate: report.normalization.startDate,
                endDate: report.normalization.endDate,
                orderingNormalized: inference.inferredSettings.reverse == true
            )
        }
        let rowFailures = diagnosticRowFailures(
            preparedCSV: preparedCSV,
            inference: inference,
            preview: preview,
            validation: validation,
            normalization: normalization,
            maxFailureRows: normalizedMaxFailureRows
        )
        let isImportViable = diagnosticIsImportViable(validation: validation)

        return BKAppCSVImportDiagnosticsReport(
            symbol: symbol,
            inspection: inspection,
            inference: inference,
            stageDecisions: stageDecisions,
            failureStage: failureStage,
            rowFailures: rowFailures,
            previewSummary: previewSummary,
            normalizationSummary: normalizationSummary,
            isImportViable: isImportViable
        )
    }

    /// Builds the full import-review state for an app-facing CSV import screen before execution.
    public static func buildCSVImportScreenState(
        symbol: String,
        csv: String,
        maxRows: Int = 5
    ) -> BKAppCSVImportScreenState {
        let inspection = inspectCSV(symbol: symbol, csv: csv)
        let inference = detectCSVImportSettings(symbol: symbol, csv: csv)

        let canAttemptPreview = canAttemptImportPreview(with: inspection, csv: csv)
        let preview = canAttemptPreview
            ? previewCSVAuto(symbol: symbol, csv: csv, maxRows: maxRows)
            : nil

        let canAttemptValidation = canAttemptImportValidation(
            inspection: inspection,
            preview: preview
        )
        let validation = canAttemptValidation
            ? validateCSVImportAuto(symbol: symbol, csv: csv)
            : nil

        let canAttemptNormalization = validation?.validation.isSuccessful == true
        let normalization = canAttemptNormalization
            ? normalizeCSVImportAuto(symbol: symbol, csv: csv)
            : nil

        let issues = buildImportIssueSections(
            inspection: inspection,
            inference: inference,
            validation: validation
        )
        let status = importScreenStatus(
            inspection: inspection,
            validation: validation,
            normalization: normalization,
            issues: issues
        )

        return BKAppCSVImportScreenState(
            symbol: symbol,
            inspection: inspection,
            inference: inference,
            preview: preview,
            validation: validation,
            normalization: normalization,
            issues: issues,
            status: status,
            isReadyToContinue: status == .ready
        )
    }

    /// Runs a preset import using settings confirmed after an app-side review step.
    public static func runConfirmedCSVImport(
        from screenState: BKAppCSVImportScreenState,
        csv: String,
        preset: BKPresetCatalog,
        confirmedSettings: BKAppCSVConfirmedImportSettings? = nil,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> BKAppCSVConfirmedRunReport {
        let settings = confirmedSettings ?? BKAppCSVConfirmedImportSettings(
            columnMapping: screenState.inference.effectiveSettings.columnMapping,
            dateFormat: screenState.inference.effectiveSettings.dateFormat,
            reverse: screenState.inference.effectiveSettings.reverse
        )
        let effectiveCSV = confirmedSettings == nil
            ? autoPreparedCSV(csv: csv, inference: screenState.inference)
            : csv

        let run = runCSVImport(
            symbol: screenState.symbol,
            csv: effectiveCSV,
            preset: preset,
            dateFormat: settings.dateFormat,
            reverse: settings.reverse,
            columnMapping: settings.columnMapping,
            log: log
        )

        return BKAppCSVConfirmedRunReport(
            confirmedSettings: settings,
            run: run
        )
    }

    /// Builds the full review state for an app-facing portfolio basket before execution.
    public static func buildPortfolioCSVImportScreenState(
        portfolioID: String = "PORTFOLIO",
        sleeves: [BKAppPortfolioImportItem],
        allocation: BKPortfolioAllocationInput = .sleeveWeights,
        rebalancePolicy: BKPortfolioRebalancePolicy = .none,
        maxRows: Int = 5
    ) -> BKAppPortfolioImportScreenState {
        let normalizedPortfolioID = portfolioID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "PORTFOLIO"
            : portfolioID
        let sleeveStates = sleeves.map { sleeve in
            BKAppPortfolioImportItemState(
                request: sleeve,
                screenState: buildCSVImportScreenState(
                    symbol: sleeve.symbol,
                    csv: sleeve.csv,
                    maxRows: maxRows
                )
            )
        }

        let sleeveIssues = sleeveStates.flatMap { sleeveState in
            sleeveState.screenState.issues.map { section in
                BKAppPortfolioImportIssueSection(
                    symbol: sleeveState.request.symbol,
                    title: section.title,
                    items: section.items
                )
            }
        }
        let portfolioIssues = buildPortfolioImportIssueSections(
            portfolioID: normalizedPortfolioID,
            sleeves: sleeveStates,
            allocation: allocation
        )
        let issues = sleeveIssues + portfolioIssues

        let status: BKAppCSVImportScreenStatus
        if sleeveStates.isEmpty
            || !portfolioIssues.isEmpty
            || sleeveStates.contains(where: { $0.screenState.status == .invalid }) {
            status = .invalid
        } else if sleeveStates.contains(where: { $0.screenState.status == .needsReview }) {
            status = .needsReview
        } else {
            status = .ready
        }

        return BKAppPortfolioImportScreenState(
            portfolioID: normalizedPortfolioID,
            sleeves: sleeveStates,
            allocation: allocation,
            rebalancePolicy: rebalancePolicy,
            issues: issues,
            status: status,
            isReadyToContinue: status == .ready
        )
    }

    /// Runs a confirmed app-side basket import using either explicit overrides or inferred settings per sleeve.
    public static func runConfirmedPortfolioCSVImport(
        from screenState: BKAppPortfolioImportScreenState,
        confirmedSettingsBySymbol: [String: BKAppCSVConfirmedImportSettings] = [:],
        continueOnFailure: Bool = true,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> BKAppPortfolioConfirmedRunReport {
        let sleeves = screenState.sleeves.map { sleeveState -> BKPortfolioSleeveRequest in
            let confirmedSettings = confirmedSettingsBySymbol[sleeveState.request.symbol]
            let settings = confirmedSettings ?? BKAppCSVConfirmedImportSettings(
                columnMapping: sleeveState.screenState.inference.effectiveSettings.columnMapping,
                dateFormat: sleeveState.screenState.inference.effectiveSettings.dateFormat,
                reverse: sleeveState.screenState.inference.effectiveSettings.reverse
            )
            let effectiveCSV = confirmedSettings == nil
                ? autoPreparedCSV(
                    csv: sleeveState.request.csv,
                    inference: sleeveState.screenState.inference
                )
                : sleeveState.request.csv

            return BKPortfolioSleeveRequest(
                symbol: sleeveState.request.symbol,
                csv: effectiveCSV,
                preset: sleeveState.request.preset,
                dateFormat: settings.dateFormat,
                reverse: settings.reverse,
                columnMapping: settings.columnMapping,
                targetWeight: sleeveState.request.targetWeight
            )
        }

        let request = BKEngine.PortfolioRequest(
            portfolioID: screenState.portfolioID,
            sleeves: sleeves,
            allocation: screenState.allocation,
            rebalancePolicy: screenState.rebalancePolicy,
            continueOnFailure: continueOnFailure
        )

        return BKAppPortfolioConfirmedRunReport(
            confirmedSettingsBySymbol: confirmedSettingsBySymbol,
            run: BKEngine.runPortfolio(request, log: log)
        )
    }

    /// Runs CSV inspection, validation, normalization, and preset execution in one app-facing helper.
    public static func runCSVImport(
        symbol: String,
        csv: String,
        preset: BKPresetCatalog,
        dateFormat: String = "yyyy-MM-dd",
        reverse: Bool = false,
        columnMapping: BKCSVColumnMapping? = nil,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> BKAppCSVImportRunReport {
        let normalization = normalizeCSVImport(
            symbol: symbol,
            csv: csv,
            dateFormat: dateFormat,
            reverse: reverse,
            columnMapping: columnMapping
        )

        guard normalization.isSuccessful else {
            return BKAppCSVImportRunReport(
                symbol: symbol,
                preset: preset,
                validation: normalization.validation,
                normalization: normalization,
                failureDescription: normalization.parseError ?? firstErrorMessage(in: normalization.validation),
                isSuccessful: false
            )
        }

        let run = preflightAndRunCSV(
            symbol: symbol,
            csv: csv,
            preset: preset,
            dateFormat: dateFormat,
            reverse: reverse,
            columnMapping: columnMapping,
            log: log
        )

        return BKAppCSVImportRunReport(
            symbol: symbol,
            preset: preset,
            validation: normalization.validation,
            normalization: normalization,
            run: run,
            summary: run.summary,
            failureDescription: run.failure?.message ?? firstErrorMessage(in: normalization.validation),
            isSuccessful: run.isSuccessful
        )
    }

    /// Detects CSV import settings, applies safe defaults, and runs the preset import path.
    public static func runCSVImportAuto(
        symbol: String,
        csv: String,
        preset: BKPresetCatalog,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> BKAppCSVAutoRunReport {
        let inference = detectCSVImportSettings(symbol: symbol, csv: csv)
        let effectiveCSV = autoPreparedCSV(csv: csv, inference: inference)
        let run = runCSVImport(
            symbol: symbol,
            csv: effectiveCSV,
            preset: preset,
            dateFormat: inference.effectiveSettings.dateFormat,
            reverse: inference.effectiveSettings.reverse,
            columnMapping: inference.effectiveSettings.columnMapping,
            log: log
        )

        return BKAppCSVAutoRunReport(
            inference: inference,
            run: run
        )
    }

    /// Runs CSV import orchestration and exports a successful result as Markdown.
    public static func runCSVImportAndExportMarkdown(
        symbol: String,
        csv: String,
        preset: BKPresetCatalog,
        dateFormat: String = "yyyy-MM-dd",
        reverse: Bool = false,
        columnMapping: BKCSVColumnMapping? = nil,
        title: String? = nil,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> BKAppCSVImportMarkdownReport {
        let run = runCSVImport(
            symbol: symbol,
            csv: csv,
            preset: preset,
            dateFormat: dateFormat,
            reverse: reverse,
            columnMapping: columnMapping,
            log: log
        )

        guard let summary = run.summary else {
            return BKAppCSVImportMarkdownReport(
                run: run,
                isSuccessful: false
            )
        }

        switch exportMarkdownSummary(summary, title: title) {
        case .success(let markdown):
            return BKAppCSVImportMarkdownReport(
                run: run,
                markdown: markdown,
                isSuccessful: true
            )
        case .failure(let error):
            return BKAppCSVImportMarkdownReport(
                run: run,
                exportError: error,
                isSuccessful: false
            )
        }
    }

    /// Detects CSV import settings, applies safe defaults, runs the preset import path, and exports Markdown.
    public static func runCSVImportAutoAndExportMarkdown(
        symbol: String,
        csv: String,
        preset: BKPresetCatalog,
        title: String? = nil,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> BKAppCSVAutoMarkdownReport {
        let inference = detectCSVImportSettings(symbol: symbol, csv: csv)
        let effectiveCSV = autoPreparedCSV(csv: csv, inference: inference)
        let run = runCSVImportAndExportMarkdown(
            symbol: symbol,
            csv: effectiveCSV,
            preset: preset,
            dateFormat: inference.effectiveSettings.dateFormat,
            reverse: inference.effectiveSettings.reverse,
            columnMapping: inference.effectiveSettings.columnMapping,
            title: title,
            log: log
        )

        return BKAppCSVAutoMarkdownReport(
            inference: inference,
            run: run
        )
    }

    /// Runs a deterministic scenario and returns a compact summary.
    public static func runScenario(config: BKScenarioConfig) -> BKRunSummary {
        BKEngine.runScenario(config: config)
    }

    /// Runs CSV preflight, request validation, and v2 execution in one bundled helper.
    public static func runV2ValidatedCSV(
        instrumentID: String,
        config: BKV2.SimulationPolicyConfig,
        csv: String,
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        csvColumnMapping: BKCSVColumnMapping? = nil,
        log: (@Sendable (String) -> Void)? = nil
    ) async -> BKV2ValidatedRunReport {
        await BKEngine.runV2ValidatedCSV(
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

    /// Runs CSV preflight, request validation, and v3 execution in one bundled helper.
    public static func runV3ValidatedCSV(
        instrument: BKV3_InstrumentInfo,
        dataStore: BKV3DataStore,
        csv: String,
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd",
        executionOptions: BKSimulationExecutionOptions = .init(),
        log: (@Sendable (String) -> Void)? = nil
    ) async -> BKV3ValidatedRunReport {
        await BKEngine.runV3ValidatedCSV(
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

    /// Exports a compact run summary as human-readable Markdown.
    public static func exportMarkdownSummary(
        _ summary: BKRunSummary,
        title: String? = nil
    ) -> Result<String, BKExportError> {
        BKExportTool.exportMarkdownSummary(summary, title: title)
    }

    /// Exports a completed run into a portable bundle.
    public static func exportRunBundle(
        summary: BKRunSummary,
        trades: [BKTrade] = [],
        diagnostics: BKDiagnosticsSnapshotReport? = nil,
        scenario: BKScenarioConfig? = nil,
        prettyPrinted: Bool = true
    ) -> Result<BKRunExportBundle, BKExportError> {
        BKExportTool.exportRunBundle(
            summary: summary,
            trades: trades,
            diagnostics: diagnostics,
            scenario: scenario,
            prettyPrinted: prettyPrinted
        )
    }

    /// Exports a completed portfolio run into a portable bundle.
    public static func exportPortfolioRunBundle(
        _ report: BKPortfolioRunReport,
        prettyPrinted: Bool = true
    ) -> Result<BKPortfolioExportBundle, BKExportError> {
        BKExportTool.exportPortfolioRunBundle(
            report,
            prettyPrinted: prettyPrinted
        )
    }

    /// Exports a portfolio summary as human-readable Markdown.
    public static func exportPortfolioMarkdownSummary(
        _ report: BKPortfolioRunReport,
        title: String? = nil
    ) -> Result<String, BKExportError> {
        BKExportTool.exportPortfolioMarkdownSummary(
            report,
            title: title
        )
    }

    /// Compares two summaries and flags differences larger than the supplied tolerance.
    public static func compareRuns(
        baseline: BKRunSummary,
        candidate: BKRunSummary,
        tolerance: Double = 1e-9
    ) -> BKRunComparisonReport {
        BKComparisonTool.compareRuns(
            baseline: baseline,
            candidate: candidate,
            tolerance: tolerance
        )
    }

    /// Throws when two run summaries are not equivalent within the supplied tolerance.
    @discardableResult
    public static func assertEquivalent(
        baseline: BKRunSummary,
        candidate: BKRunSummary,
        tolerance: Double = 1e-9
    ) throws -> BKRunComparisonReport {
        try BKComparisonTool.assertEquivalent(
            baseline: baseline,
            candidate: candidate,
            tolerance: tolerance
        )
    }

    /// Runs inline CSV through a preset-backed workflow, then exports the successful result as Markdown.
    public static func runPresetCSVAndExportMarkdown(
        symbol: String,
        csv: String,
        preset: BKPresetCatalog,
        dateFormat: String = "yyyy-MM-dd",
        reverse: Bool = false,
        columnMapping: BKCSVColumnMapping? = nil,
        title: String? = nil,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> BKAppPresetMarkdownReport {
        let run = preflightAndRunCSV(
            symbol: symbol,
            csv: csv,
            preset: preset,
            dateFormat: dateFormat,
            reverse: reverse,
            columnMapping: columnMapping,
            log: log
        )

        guard let summary = run.summary else {
            return BKAppPresetMarkdownReport(
                run: run,
                isSuccessful: false
            )
        }

        switch exportMarkdownSummary(summary, title: title) {
        case .success(let markdown):
            return BKAppPresetMarkdownReport(
                run: run,
                markdown: markdown,
                isSuccessful: true
            )
        case .failure(let error):
            return BKAppPresetMarkdownReport(
                run: run,
                exportError: error,
                isSuccessful: false
            )
        }
    }

    /// Runs a deterministic scenario and exports the result as a portable bundle.
    public static func runScenarioAndExportBundle(
        config: BKScenarioConfig,
        diagnostics: BKDiagnosticsSnapshotReport? = nil,
        prettyPrinted: Bool = true
    ) -> BKAppScenarioBundleReport {
        let summary = runScenario(config: config)

        switch exportRunBundle(
            summary: summary,
            diagnostics: diagnostics,
            scenario: config,
            prettyPrinted: prettyPrinted
        ) {
        case .success(let bundle):
            return BKAppScenarioBundleReport(
                config: config,
                summary: summary,
                exportBundle: bundle,
                isSuccessful: true
            )
        case .failure(let error):
            return BKAppScenarioBundleReport(
                config: config,
                summary: summary,
                exportError: error,
                isSuccessful: false
            )
        }
    }

    private static func parseImportBars(
        csv: String,
        dateFormat: String,
        reverse: Bool,
        columnMapping: BKCSVColumnMapping?
    ) -> Result<[BKBar], Error> {
        BKQuickDemo.parseBars(
            csv: csv,
            dateFormat: dateFormat,
            reverse: reverse,
            columnMapping: columnMapping
        )
    }

    private static func diagnosticInspectionOutcome(
        for inspection: BKAppCSVInspectionReport
    ) -> BKAppCSVImportStageOutcome {
        if inspection.errorCount > 0 {
            return .failed
        }
        if inspection.warningCount > 0 {
            return .warning
        }
        return .success
    }

    private static func diagnosticInspectionMessage(
        for inspection: BKAppCSVInspectionReport
    ) -> String {
        if inspection.errorCount > 0 {
            return "Inspection found \(inspection.errorCount) error(s) and \(inspection.warningCount) warning(s)."
        }
        if inspection.warningCount > 0 {
            return "Inspection found \(inspection.warningCount) warning(s)."
        }
        return "Inspection found no issues."
    }

    private static func diagnosticInferenceOutcome(
        for inference: BKAppCSVInferenceReport
    ) -> BKAppCSVImportStageOutcome {
        if inference.issues.contains(where: { $0.severity == .error }) {
            return .failed
        }
        if inference.issues.contains(where: { $0.severity == .warning }) {
            return .warning
        }
        return .success
    }

    private static func diagnosticInferenceMessage(
        for inference: BKAppCSVInferenceReport
    ) -> String {
        if inference.issues.isEmpty {
            return "Inference resolved settings without warnings."
        }
        if inference.issues.contains(where: { $0.severity == .error }) {
            return "Inference produced \(inference.issues.count) issue(s)."
        }
        return "Inference produced \(inference.issues.count) warning(s)."
    }

    private static func diagnosticShouldAttemptPreview(
        with inspection: BKAppCSVInspectionReport,
        csv: String
    ) -> Bool {
        !csv.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && inspection.errorCount == 0
    }

    private static func diagnosticAttemptPreview(
        symbol: String,
        csv: String
    ) throws -> BKAppCSVAutoPreviewReport {
        previewCSVAuto(symbol: symbol, csv: csv)
    }

    private static func diagnosticPreviewOutcome(
        preview: BKAppCSVAutoPreviewReport?,
        canAttempt: Bool,
        inspection: BKAppCSVInspectionReport
    ) -> BKAppCSVImportStageOutcome {
        guard canAttempt else { return .skipped }
        guard let preview else { return .failed }
        guard preview.preview.isSuccessful else { return .failed }
        return preview.preview.rowCount == 0 ? .warning : .success
    }

    private static func diagnosticPreviewMessage(
        canAttempt: Bool,
        preview: BKAppCSVAutoPreviewReport?,
        inspection: BKAppCSVInspectionReport
    ) -> String {
        guard canAttempt else {
            return "Preview skipped because inspection was not clean enough to attempt parsing."
        }
        guard let preview else {
            return "Preview failed before producing a report."
        }
        guard preview.preview.isSuccessful else {
            return preview.preview.parseError ?? "Preview failed while parsing rows."
        }

        var details = "Preview parsed \(preview.preview.rowCount) row(s)."
        if let startDate = preview.preview.startDate, let endDate = preview.preview.endDate {
            details += " Range: \(startDate.ISO8601Format()) to \(endDate.ISO8601Format())."
        }
        return details
    }

    private static func diagnosticPreviewSkippedMessage(
        inspection: BKAppCSVInspectionReport
    ) -> String {
        guard inspection.errorCount == 0 else {
            return "Preview skipped because inspection reported errors."
        }
        return "Preview skipped because the CSV could not be prepared safely."
    }

    private static func diagnosticShouldAttemptValidation(
        preview: BKAppCSVAutoPreviewReport?
    ) -> Bool {
        preview?.preview.isSuccessful == true
    }

    private static func diagnosticAttemptValidation(
        symbol: String,
        csv: String
    ) throws -> BKAppCSVAutoValidationReport {
        validateCSVImportAuto(symbol: symbol, csv: csv)
    }

    private static func diagnosticValidationOutcome(
        validation: BKAppCSVAutoValidationReport?,
        canAttempt: Bool
    ) -> BKAppCSVImportStageOutcome {
        guard canAttempt else { return .skipped }
        guard let validation else { return .failed }
        return validation.validation.isSuccessful ? .success : .failed
    }

    private static func diagnosticValidationMessage(
        canAttempt: Bool,
        validation: BKAppCSVAutoValidationReport?
    ) -> String {
        guard canAttempt else {
            return "Validation skipped because preview did not succeed."
        }
        guard let validation else {
            return "Validation failed before producing a report."
        }
        if validation.validation.isSuccessful {
            return "Validation succeeded."
        }
        return validation.validation.parseError ?? firstErrorMessage(in: validation.validation) ?? "Validation failed."
    }

    private static func diagnosticValidationSkippedMessage(
        preview: BKAppCSVAutoPreviewReport?
    ) -> String {
        guard preview != nil else {
            return "Validation skipped because preview was not available."
        }
        return "Validation skipped because preview did not succeed."
    }

    private static func diagnosticShouldAttemptNormalization(
        validation: BKAppCSVAutoValidationReport?
    ) -> Bool {
        validation?.validation.isSuccessful == true
    }

    private static func diagnosticAttemptNormalization(
        symbol: String,
        csv: String
    ) throws -> BKAppCSVAutoNormalizedReport {
        normalizeCSVImportAuto(symbol: symbol, csv: csv)
    }

    private static func diagnosticNormalizationOutcome(
        normalization: BKAppCSVAutoNormalizedReport?,
        canAttempt: Bool
    ) -> BKAppCSVImportStageOutcome {
        guard canAttempt else { return .skipped }
        guard let normalization else { return .failed }
        guard normalization.normalization.isSuccessful else { return .failed }
        return normalization.normalization.rowCount == 0 ? .warning : .success
    }

    private static func diagnosticNormalizationMessage(
        canAttempt: Bool,
        normalization: BKAppCSVAutoNormalizedReport?
    ) -> String {
        guard canAttempt else {
            return "Normalization skipped because validation did not succeed."
        }
        guard let normalization else {
            return "Normalization failed before producing a report."
        }
        guard normalization.normalization.isSuccessful else {
            return normalization.normalization.parseError
                ?? firstErrorMessage(in: normalization.normalization.validation)
                ?? "Normalization failed."
        }

        var details = "Normalization produced \(normalization.normalization.rowCount) bar(s)."
        if let startDate = normalization.normalization.startDate, let endDate = normalization.normalization.endDate {
            details += " Range: \(startDate.ISO8601Format()) to \(endDate.ISO8601Format())."
        }
        if normalization.normalization.rowCount == 0 {
            details += " No normalized rows were available."
        }
        return details
    }

    private static func diagnosticNormalizationSkippedMessage(
        validation: BKAppCSVAutoValidationReport?
    ) -> String {
        guard validation != nil else {
            return "Normalization skipped because validation was not available."
        }
        return "Normalization skipped because validation did not succeed."
    }

    private static func diagnosticAppendSkippedDecisions(
        after stage: BKAppCSVImportDiagnosticStage,
        inspection: BKAppCSVInspectionReport,
        preview: BKAppCSVAutoPreviewReport?,
        validation: BKAppCSVAutoValidationReport?,
        stageDecisions: inout [BKAppCSVImportStageDecision]
    ) {
        switch stage {
        case .inspection, .inference:
            stageDecisions.append(
                BKAppCSVImportStageDecision(
                    stage: .preview,
                    outcome: .skipped,
                    message: diagnosticPreviewSkippedMessage(inspection: inspection)
                )
            )
            stageDecisions.append(
                BKAppCSVImportStageDecision(
                    stage: .validation,
                    outcome: .skipped,
                    message: diagnosticValidationSkippedMessage(preview: preview)
                )
            )
            stageDecisions.append(
                BKAppCSVImportStageDecision(
                    stage: .normalization,
                    outcome: .skipped,
                    message: diagnosticNormalizationSkippedMessage(validation: validation)
                )
            )
        case .preview:
            stageDecisions.append(
                BKAppCSVImportStageDecision(
                    stage: .validation,
                    outcome: .skipped,
                    message: diagnosticValidationSkippedMessage(preview: preview)
                )
            )
            stageDecisions.append(
                BKAppCSVImportStageDecision(
                    stage: .normalization,
                    outcome: .skipped,
                    message: diagnosticNormalizationSkippedMessage(validation: validation)
                )
            )
        case .validation:
            stageDecisions.append(
                BKAppCSVImportStageDecision(
                    stage: .normalization,
                    outcome: .skipped,
                    message: diagnosticNormalizationSkippedMessage(validation: validation)
                )
            )
        case .normalization:
            break
        }
    }

    private static func diagnosticIsImportViable(
        validation: BKAppCSVAutoValidationReport?
    ) -> Bool {
        validation?.validation.isSuccessful == true
    }

    private static func diagnosticUnexpectedFailureMessage(
        stage: BKAppCSVImportDiagnosticStage,
        error: Error
    ) -> String {
        "Unexpected \(stage.rawValue) failure: \(describe(error))."
    }

    private static func diagnosticRowFailures(
        preparedCSV: String,
        inference: BKAppCSVInferenceReport,
        preview: BKAppCSVAutoPreviewReport?,
        validation: BKAppCSVAutoValidationReport?,
        normalization: BKAppCSVAutoNormalizedReport?,
        maxFailureRows: Int
    ) -> [BKAppCSVRowFailureExample] {
        guard maxFailureRows > 0 else { return [] }
        guard preview?.preview.isSuccessful == false
            || validation?.validation.isSuccessful == false
            || normalization?.normalization.isSuccessful == false else {
            return []
        }

        let parseResult = parseImportBars(
            csv: preparedCSV,
            dateFormat: inference.effectiveSettings.dateFormat,
            reverse: inference.effectiveSettings.reverse,
            columnMapping: inference.effectiveSettings.columnMapping
        )

        guard case .failure(let error) = parseResult,
              let parsingError = error as? BKCSVParsingError else {
            return []
        }

        guard let rowFailure = diagnosticRowFailureExample(
            from: parsingError,
            csv: preparedCSV
        ) else {
            return []
        }

        return [rowFailure]
    }

    private static func diagnosticRowFailureExample(
        from error: BKCSVParsingError,
        csv: String
    ) -> BKAppCSVRowFailureExample? {
        let normalized = csv.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)

        switch error {
        case .invalidISO8601Date(_, let line),
             .malformedRow(let line),
             .invalidNumeric(_, let line),
             .nonChronologicalDate(_, _, let line):
            let index = line - 1
            guard index >= 0, index < lines.count else { return nil }
            return BKAppCSVRowFailureExample(
                rowIndex: line,
                rawRow: lines[index],
                message: describe(error)
            )
        case .missingHeader,
             .missingRequiredColumn,
             .invalidDate:
            return nil
        }
    }

    private static func makePreviewRow(from bar: BKBar) -> BKAppCSVPreviewRow {
        BKAppCSVPreviewRow(
            date: bar.time,
            open: bar.open,
            high: bar.high,
            low: bar.low,
            close: bar.close,
            adjustedClose: bar.adjustedClose,
            volume: bar.volume
        )
    }

    private static func firstErrorMessage(in validation: BKAppCSVValidationReport) -> String? {
        validation.inspection.preflight.validation.issues.first(where: { $0.severity == .error })?.message
            ?? validation.parseValidation.issues.first(where: { $0.severity == .error })?.message
    }

    private static func canAttemptImportPreview(
        with inspection: BKAppCSVInspectionReport,
        csv: String
    ) -> Bool {
        !csv.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !inspection.preflight.validation.issues.contains(where: { $0.code == "csv_empty" })
    }

    private static func canAttemptImportValidation(
        inspection: BKAppCSVInspectionReport,
        preview: BKAppCSVAutoPreviewReport?
    ) -> Bool {
        guard !inspection.preflight.validation.issues.contains(where: { $0.code == "csv_empty" }) else {
            return false
        }
        guard let preview else { return false }
        return preview.preview.isSuccessful || inspection.preflight.rowCount != nil
    }

    private static func buildImportIssueSections(
        inspection: BKAppCSVInspectionReport,
        inference: BKAppCSVInferenceReport,
        validation: BKAppCSVAutoValidationReport?
    ) -> [BKAppCSVImportIssueSection] {
        var sections: [BKAppCSVImportIssueSection] = []

        let inspectionItems = inspection.preflight.validation.issues.map { issue in
            BKAppCSVImportIssueItem(
                severity: issue.severity,
                code: issue.code,
                message: issue.message,
                source: .inspection
            )
        }
        if !inspectionItems.isEmpty {
            sections.append(BKAppCSVImportIssueSection(title: "Inspection", items: inspectionItems))
        }

        let inferenceItems = inference.issues.map { issue in
            BKAppCSVImportIssueItem(
                severity: issue.severity,
                code: issue.code,
                message: issue.message,
                source: .inference
            )
        }
        if !inferenceItems.isEmpty {
            sections.append(BKAppCSVImportIssueSection(title: "Inference", items: inferenceItems))
        }

        let validationItems = validation?.validation.parseValidation.issues.map { issue in
            BKAppCSVImportIssueItem(
                severity: issue.severity,
                code: issue.code,
                message: issue.message,
                source: .validation
            )
        } ?? []
        if !validationItems.isEmpty {
            sections.append(BKAppCSVImportIssueSection(title: "Validation", items: validationItems))
        }

        return sections
    }

    private static func buildPortfolioImportIssueSections(
        portfolioID: String,
        sleeves: [BKAppPortfolioImportItemState],
        allocation: BKPortfolioAllocationInput
    ) -> [BKAppPortfolioImportIssueSection] {
        var items: [BKAppCSVImportIssueItem] = []
        let duplicateSymbols = duplicatePortfolioImportSymbols(in: sleeves)
        if !duplicateSymbols.isEmpty {
            items.append(
                BKAppCSVImportIssueItem(
                    severity: .error,
                    code: "portfolio_duplicate_symbols",
                    message: "Portfolio sleeve symbols must be unique. Duplicates: \(duplicateSymbols.joined(separator: ", ")).",
                    source: .validation
                )
            )
        }

        switch allocation.mode {
        case .explicit:
            let weights = allocation.explicitWeights ?? []
            if weights.count != sleeves.count {
                items.append(
                    BKAppCSVImportIssueItem(
                        severity: .error,
                        code: "portfolio_explicit_weight_count_mismatch",
                        message: "Explicit portfolio weights must match the sleeve count.",
                        source: .validation
                    )
                )
            } else {
                let clampedTotal = weights.reduce(0.0) { partial, weight in
                    partial + max(weight, 0)
                }
                if clampedTotal <= 0 {
                    items.append(
                        BKAppCSVImportIssueItem(
                            severity: .error,
                            code: "portfolio_explicit_weight_total_invalid",
                            message: "Explicit portfolio weights must resolve to a positive total.",
                            source: .validation
                        )
                    )
                }
            }

        case .riskOnRiskOff:
            let count = sleeves.count
            let riskOnIndex = allocation.riskOnIndex ?? 0
            let riskOffIndex = allocation.riskOffIndex ?? 1
            if !(riskOnIndex >= 0
                && riskOnIndex < count
                && riskOffIndex >= 0
                && riskOffIndex < count
                && riskOnIndex != riskOffIndex) {
                items.append(
                    BKAppCSVImportIssueItem(
                        severity: .error,
                        code: "portfolio_risk_on_risk_off_indices",
                        message: "Risk-on / risk-off allocation requires two distinct valid sleeve indices.",
                        source: .validation
                    )
                )
            }

        case .sleeveWeights, .riskParity:
            break
        }

        guard !items.isEmpty else { return [] }
        return [BKAppPortfolioImportIssueSection(symbol: portfolioID, title: "Portfolio", items: items)]
    }

    private static func duplicatePortfolioImportSymbols(
        in sleeves: [BKAppPortfolioImportItemState]
    ) -> [String] {
        var seen: Set<String> = []
        var duplicates: Set<String> = []

        for sleeve in sleeves {
            let symbol = sleeve.request.symbol.trimmingCharacters(in: .whitespacesAndNewlines)
            if seen.contains(symbol) {
                duplicates.insert(symbol)
            } else {
                seen.insert(symbol)
            }
        }

        return duplicates.sorted()
    }

    private static func importScreenStatus(
        inspection: BKAppCSVInspectionReport,
        validation: BKAppCSVAutoValidationReport?,
        normalization: BKAppCSVAutoNormalizedReport?,
        issues: [BKAppCSVImportIssueSection]
    ) -> BKAppCSVImportScreenStatus {
        if !inspection.isReady {
            return .invalid
        }

        if let validation, !validation.validation.isSuccessful {
            return .invalid
        }

        let ready = validation?.validation.isSuccessful == true && normalization?.normalization.isSuccessful == true
        if ready {
            let hasWarnings = issues
                .flatMap(\.items)
                .contains(where: { $0.severity == .warning })
            return hasWarnings ? .needsReview : .ready
        }

        return .needsReview
    }

    private static func describe(_ error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return String(describing: error)
    }

    private static let defaultAutoCSVDateFormat = "yyyy-MM-dd"
    private static let defaultAutoCSVReverse = false

    private enum AutoCSVField: CaseIterable {
        case date
        case open
        case high
        case low
        case close
        case adjustedClose
        case volume
    }

    private struct AutoCSVInferenceDetection {
        var inferredSettings: BKAppCSVInferredSettings
        var effectiveSettings: BKAppCSVEffectiveSettings
        var issues: [BKAppCSVInferenceIssue]
        var isFullyInferred: Bool
    }

    private static func detectAutoCSVInference(csv: String) -> AutoCSVInferenceDetection {
        let fallbackSettings = BKAppCSVEffectiveSettings(
            columnMapping: nil,
            dateFormat: defaultAutoCSVDateFormat,
            reverse: defaultAutoCSVReverse
        )
        let parsedCSV = parseCSVStructure(csv)
        guard let parsedCSV else {
            return AutoCSVInferenceDetection(
                inferredSettings: BKAppCSVInferredSettings(),
                effectiveSettings: fallbackSettings,
                issues: [
                    BKAppCSVInferenceIssue(
                        code: "csv_inference_missing_header",
                        message: "Could not infer CSV settings because the header row is missing.",
                        severity: .error
                    )
                ],
                isFullyInferred: false
            )
        }

        var issues: [BKAppCSVInferenceIssue] = []
        let mappingInference = inferColumnMapping(from: parsedCSV.headers)
        issues.append(contentsOf: mappingInference.issues)

        let effectiveDateHeader = mappingInference.effectiveDateHeader
        let dateSamples = collectDateSamples(
            rows: parsedCSV.rows,
            headers: parsedCSV.headers,
            header: effectiveDateHeader
        )
        let dateFormatInference = inferDateFormat(from: dateSamples)
        issues.append(contentsOf: dateFormatInference.issues)

        let reverseInference = inferChronologicalOrder(from: dateSamples)
        issues.append(contentsOf: reverseInference.issues)

        let inferredSettings = BKAppCSVInferredSettings(
            columnMapping: mappingInference.columnMapping,
            dateFormat: dateFormatInference.dateFormat,
            reverse: reverseInference.reverse
        )

        let effectiveSettings = BKAppCSVEffectiveSettings(
            columnMapping: mappingInference.columnMapping,
            dateFormat: dateFormatInference.dateFormat ?? defaultAutoCSVDateFormat,
            reverse: effectiveReverseFlag(for: reverseInference.reverse)
        )

        let isFullyInferred =
            inferredSettings.columnMapping != nil &&
            inferredSettings.dateFormat != nil &&
            inferredSettings.reverse != nil

        return AutoCSVInferenceDetection(
            inferredSettings: inferredSettings,
            effectiveSettings: effectiveSettings,
            issues: issues,
            isFullyInferred: isFullyInferred
        )
    }

    private static func effectiveReverseFlag(for inferredReverse: Bool?) -> Bool {
        guard let inferredReverse else { return defaultAutoCSVReverse }
        return inferredReverse ? false : inferredReverse
    }

    private static func autoPreparedCSV(
        csv: String,
        inference: BKAppCSVInferenceReport
    ) -> String {
        guard inference.inferredSettings.reverse == true else {
            return csv
        }
        return reorderCSVChronologically(csv)
    }

    private static func reorderCSVChronologically(_ csv: String) -> String {
        guard let parsedCSV = parseCSVStructure(csv) else {
            return csv
        }

        let nonEmptyRows = parsedCSV.rows.filter { !$0.rawLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let reorderedRows = nonEmptyRows.reversed().map(\.rawLine)
        return ([parsedCSV.headerLine] + reorderedRows).joined(separator: "\n")
    }

    private struct ParsedCSVStructure {
        var headerLine: String
        var headers: [String]
        var rows: [ParsedCSVRow]
    }

    private struct ParsedCSVRow {
        var rawLine: String
        var fields: [String]
    }

    private static func parseCSVStructure(_ csv: String) -> ParsedCSVStructure? {
        let normalized = csv.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        guard let headerLine = lines.first else { return nil }

        let headers = headerLine
            .split(separator: ",", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        let rows = lines.dropFirst().map { line in
            ParsedCSVRow(
                rawLine: line,
                fields: line
                    .split(separator: ",", omittingEmptySubsequences: false)
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            )
        }

        return ParsedCSVStructure(
            headerLine: headerLine,
            headers: headers,
            rows: rows
        )
    }

    private static func inferColumnMapping(from headers: [String]) -> (
        columnMapping: BKCSVColumnMapping?,
        effectiveDateHeader: String,
        issues: [BKAppCSVInferenceIssue]
    ) {
        var issues: [BKAppCSVInferenceIssue] = []
        let matches = Dictionary(uniqueKeysWithValues: AutoCSVField.allCases.map { field in
            (field, matchingHeaders(for: field, headers: headers))
        })

        var requiredHeaders: [AutoCSVField: String] = [:]
        var hasRequiredIssue = false

        for field in [AutoCSVField.date, .open, .high, .low, .close, .volume] {
            let fieldMatches = matches[field] ?? []
            if fieldMatches.count == 1 {
                requiredHeaders[field] = fieldMatches[0]
            } else {
                hasRequiredIssue = true
                let code = fieldMatches.isEmpty ? "csv_inference_missing_\(fieldCode(field))" : "csv_inference_ambiguous_\(fieldCode(field))"
                let message: String
                if fieldMatches.isEmpty {
                    message = "Could not safely infer the \(fieldLabel(field)) column from the CSV header."
                } else {
                    message = "Found multiple possible \(fieldLabel(field)) columns: \(fieldMatches.joined(separator: ", "))."
                }
                issues.append(
                    BKAppCSVInferenceIssue(
                        code: code,
                        message: message,
                        severity: .warning
                    )
                )
            }
        }

        let adjustedCloseHeader: String?
        let adjustedCloseMatches = matches[.adjustedClose] ?? []
        if adjustedCloseMatches.count == 1 {
            adjustedCloseHeader = adjustedCloseMatches[0]
        } else {
            adjustedCloseHeader = nil
            if adjustedCloseMatches.count > 1 {
                issues.append(
                    BKAppCSVInferenceIssue(
                        code: "csv_inference_ambiguous_adjusted_close",
                        message: "Found multiple possible adjusted close columns: \(adjustedCloseMatches.joined(separator: ", ")).",
                        severity: .warning
                    )
                )
            }
        }

        let defaultDateHeader = fallbackDateHeader(from: headers)
        guard !hasRequiredIssue,
              let dateHeader = requiredHeaders[.date],
              let openHeader = requiredHeaders[.open],
              let highHeader = requiredHeaders[.high],
              let lowHeader = requiredHeaders[.low],
              let closeHeader = requiredHeaders[.close],
              let volumeHeader = requiredHeaders[.volume]
        else {
            return (
                columnMapping: nil,
                effectiveDateHeader: defaultDateHeader,
                issues: issues
            )
        }

        issues.append(
            BKAppCSVInferenceIssue(
                code: "csv_inference_column_mapping_inferred",
                message: "Safely inferred the CSV column mapping from the header row.",
                severity: .info
            )
        )

        return (
            columnMapping: BKCSVColumnMapping(
                date: dateHeader,
                open: openHeader,
                high: highHeader,
                low: lowHeader,
                close: closeHeader,
                adjustedClose: adjustedCloseHeader,
                volume: volumeHeader
            ),
            effectiveDateHeader: dateHeader,
            issues: issues
        )
    }

    private static func collectDateSamples(
        rows: [ParsedCSVRow],
        headers: [String],
        header: String
    ) -> [String] {
        guard !rows.isEmpty else { return [] }
        guard let headerIndex = headerIndex(for: header, in: headers) else {
            return []
        }

        return rows.prefix(10).compactMap { row in
            guard headerIndex < row.fields.count else { return nil }
            let value = row.fields[headerIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }
    }

    private static func headerIndex(
        for header: String,
        in headers: [String]
    ) -> Int? {
        let normalizedTarget = atNormalizedColumnKey(header)

        if let exactMatch = headers.firstIndex(where: { atNormalizedColumnKey($0) == normalizedTarget }) {
            return exactMatch
        }

        let safeTarget = safeHeaderKey(header)
        return headers.firstIndex(where: { safeHeaderKey($0) == safeTarget })
    }

    private static func inferDateFormat(from samples: [String]) -> (
        dateFormat: String?,
        issues: [BKAppCSVInferenceIssue]
    ) {
        guard !samples.isEmpty else {
            return (
                dateFormat: nil,
                issues: [
                    BKAppCSVInferenceIssue(
                        code: "csv_inference_missing_date_samples",
                        message: "Could not sample enough date values to infer a date format.",
                        severity: .warning
                    )
                ]
            )
        }

        let candidates = supportedAutoDateFormatCandidates().filter { candidate in
            samples.allSatisfy { candidate.matches($0) }
        }

        guard candidates.count == 1 else {
            let code = candidates.isEmpty ? "csv_inference_date_format_unresolved" : "csv_inference_date_format_ambiguous"
            let message = candidates.isEmpty
                ? "Could not safely infer a supported ISO8601-compatible date format from the sampled values."
                : "Multiple supported date formats matched the sampled values."

            return (
                dateFormat: nil,
                issues: [
                    BKAppCSVInferenceIssue(
                        code: code,
                        message: message,
                        severity: .warning
                    )
                ]
            )
        }

        return (
            dateFormat: candidates[0].format,
            issues: [
                BKAppCSVInferenceIssue(
                    code: "csv_inference_date_format_inferred",
                    message: "Safely inferred the date format as \(candidates[0].format).",
                    severity: .info
                )
            ]
        )
    }

    private static func inferChronologicalOrder(from samples: [String]) -> (
        reverse: Bool?,
        issues: [BKAppCSVInferenceIssue]
    ) {
        let parsedDates = samples.compactMap(atParseISO8601Date)
        guard parsedDates.count >= 2 else {
            return (
                reverse: nil,
                issues: [
                    BKAppCSVInferenceIssue(
                        code: "csv_inference_reverse_unresolved",
                        message: "Could not safely infer CSV row order from the available date samples.",
                        severity: .warning
                    )
                ]
            )
        }

        let isAscending = zip(parsedDates, parsedDates.dropFirst()).allSatisfy(<)
        if isAscending {
            return (
                reverse: false,
                issues: [
                    BKAppCSVInferenceIssue(
                        code: "csv_inference_reverse_ascending",
                        message: "Detected chronological ascending input; auto helpers will keep `reverse = false`.",
                        severity: .info
                    )
                ]
            )
        }

        let isDescending = zip(parsedDates, parsedDates.dropFirst()).allSatisfy(>)
        if isDescending {
            return (
                reverse: true,
                issues: [
                    BKAppCSVInferenceIssue(
                        code: "csv_inference_reverse_descending",
                        message: "Detected descending input; auto helpers will normalize rows to chronological order before parsing.",
                        severity: .info
                    )
                ]
            )
        }

        return (
            reverse: nil,
            issues: [
                BKAppCSVInferenceIssue(
                    code: "csv_inference_reverse_unresolved",
                    message: "CSV row order is mixed or ambiguous, so reverse order was not inferred.",
                    severity: .warning
                )
            ]
        )
    }

    private struct AutoDateFormatCandidate {
        var format: String
        var matches: (String) -> Bool
    }

    private static func supportedAutoDateFormatCandidates() -> [AutoDateFormatCandidate] {
        [
            AutoDateFormatCandidate(
                format: "yyyy-MM-dd",
                matches: { value in
                    value.range(
                        of: #"^\d{4}-\d{2}-\d{2}$"#,
                        options: .regularExpression
                    ) != nil && atParseISO8601Date(value) != nil
                }
            ),
            AutoDateFormatCandidate(
                format: "yyyy-MM-dd'T'HH:mm:ssXXXXX",
                matches: { value in
                    value.range(
                        of: #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})$"#,
                        options: .regularExpression
                    ) != nil && atParseISO8601Date(value) != nil
                }
            ),
            AutoDateFormatCandidate(
                format: "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
                matches: { value in
                    value.range(
                        of: #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+(Z|[+-]\d{2}:\d{2})$"#,
                        options: .regularExpression
                    ) != nil && atParseISO8601Date(value) != nil
                }
            )
        ]
    }

    private static func matchingHeaders(
        for field: AutoCSVField,
        headers: [String]
    ) -> [String] {
        let aliases = safeAliases(for: field)
        return headers.filter { aliases.contains(safeHeaderKey($0)) }
    }

    private static func fallbackDateHeader(from headers: [String]) -> String {
        if let timestamp = headers.first(where: { atNormalizedColumnKey($0) == "timestamp" }) {
            return timestamp
        }
        if let time = headers.first(where: { atNormalizedColumnKey($0) == "time" }) {
            return time
        }
        if let date = headers.first(where: { atNormalizedColumnKey($0) == "date" }) {
            return date
        }
        return headers.first ?? "timestamp"
    }

    private static func safeAliases(for field: AutoCSVField) -> Set<String> {
        switch field {
        case .date:
            return Set([
                "timestamp",
                "time",
                "date",
                "datetime",
                "trade_date",
                "trading_date"
            ].map(safeHeaderKey))
        case .open:
            return Set(["open", "price_open", "open_price"].map(safeHeaderKey))
        case .high:
            return Set(["high", "price_high", "high_price"].map(safeHeaderKey))
        case .low:
            return Set(["low", "price_low", "low_price"].map(safeHeaderKey))
        case .close:
            return Set(["close", "price_close", "close_price"].map(safeHeaderKey))
        case .adjustedClose:
            return Set([
                "adjusted_close",
                "adjusted close",
                "adj_close",
                "adjclose",
                "adjustedclose",
                "price_adjusted_close"
            ].map(safeHeaderKey))
        case .volume:
            return Set(["volume", "vol", "share_volume", "trading_volume"].map(safeHeaderKey))
        }
    }

    private static func safeHeaderKey(_ value: String) -> String {
        atNormalizedColumnKey(value)
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    private static func fieldLabel(_ field: AutoCSVField) -> String {
        switch field {
        case .date: return "date"
        case .open: return "open"
        case .high: return "high"
        case .low: return "low"
        case .close: return "close"
        case .adjustedClose: return "adjusted close"
        case .volume: return "volume"
        }
    }

    private static func fieldCode(_ field: AutoCSVField) -> String {
        switch field {
        case .date: return "date"
        case .open: return "open"
        case .high: return "high"
        case .low: return "low"
        case .close: return "close"
        case .adjustedClose: return "adjusted_close"
        case .volume: return "volume"
        }
    }
}
