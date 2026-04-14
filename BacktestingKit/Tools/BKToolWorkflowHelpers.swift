import Foundation

/// Diff and comparison helpers for summary-oriented regression checks.
public enum BKComparisonTool {
    /// Produces a structured diff between two summary payloads.
    public static func diffSummaries(
        baseline: BKRunSummary,
        candidate: BKRunSummary
    ) -> BKRunSummaryDiff {
        let metrics = BKRunMetricDiff(
            baseline: baseline.metrics,
            candidate: candidate.metrics,
            tradeCountDelta: candidate.metrics.tradeCount - baseline.metrics.tradeCount,
            winRateDelta: candidate.metrics.winRate - baseline.metrics.winRate,
            totalReturnDelta: candidate.metrics.totalReturn - baseline.metrics.totalReturn,
            annualizedReturnDelta: candidate.metrics.annualizedReturn - baseline.metrics.annualizedReturn,
            maxDrawdownDelta: candidate.metrics.maxDrawdown - baseline.metrics.maxDrawdown,
            sharpeRatioDelta: candidate.metrics.sharpeRatio - baseline.metrics.sharpeRatio,
            profitFactorDelta: candidate.metrics.profitFactor - baseline.metrics.profitFactor
        )

        return BKRunSummaryDiff(
            baseline: baseline,
            candidate: candidate,
            symbolChanged: baseline.symbol != candidate.symbol,
            barCountDelta: candidate.barCount - baseline.barCount,
            startDateChanged: baseline.startDate != candidate.startDate,
            endDateChanged: baseline.endDate != candidate.endDate,
            metrics: metrics
        )
    }

    /// Compares two summaries and flags differences larger than the supplied tolerance.
    public static func compareRuns(
        baseline: BKRunSummary,
        candidate: BKRunSummary,
        tolerance: Double = 1e-9
    ) -> BKRunComparisonReport {
        let diff = diffSummaries(baseline: baseline, candidate: candidate)
        let normalizedTolerance = abs(tolerance)

        var changedFieldCount = 0
        var materiallyDifferentFields: [String] = []

        func record(_ field: String, changed: Bool, materiallyDifferent: Bool) {
            guard changed else { return }
            changedFieldCount += 1
            if materiallyDifferent {
                materiallyDifferentFields.append(field)
            }
        }

        record("symbol", changed: diff.symbolChanged, materiallyDifferent: diff.symbolChanged)
        record("barCount", changed: diff.barCountDelta != 0, materiallyDifferent: diff.barCountDelta != 0)
        record("startDate", changed: diff.startDateChanged, materiallyDifferent: diff.startDateChanged)
        record("endDate", changed: diff.endDateChanged, materiallyDifferent: diff.endDateChanged)
        record(
            "metrics.tradeCount",
            changed: diff.metrics.tradeCountDelta != 0,
            materiallyDifferent: diff.metrics.tradeCountDelta != 0
        )
        record(
            "metrics.winRate",
            changed: diff.metrics.winRateDelta != 0,
            materiallyDifferent: abs(diff.metrics.winRateDelta) > normalizedTolerance
        )
        record(
            "metrics.totalReturn",
            changed: diff.metrics.totalReturnDelta != 0,
            materiallyDifferent: abs(diff.metrics.totalReturnDelta) > normalizedTolerance
        )
        record(
            "metrics.annualizedReturn",
            changed: diff.metrics.annualizedReturnDelta != 0,
            materiallyDifferent: abs(diff.metrics.annualizedReturnDelta) > normalizedTolerance
        )
        record(
            "metrics.maxDrawdown",
            changed: diff.metrics.maxDrawdownDelta != 0,
            materiallyDifferent: abs(diff.metrics.maxDrawdownDelta) > normalizedTolerance
        )
        record(
            "metrics.sharpeRatio",
            changed: diff.metrics.sharpeRatioDelta != 0,
            materiallyDifferent: abs(diff.metrics.sharpeRatioDelta) > normalizedTolerance
        )
        record(
            "metrics.profitFactor",
            changed: diff.metrics.profitFactorDelta != 0,
            materiallyDifferent: abs(diff.metrics.profitFactorDelta) > normalizedTolerance
        )

        return BKRunComparisonReport(
            diff: diff,
            tolerance: normalizedTolerance,
            comparedFieldCount: 11,
            changedFieldCount: changedFieldCount,
            materiallyDifferentFields: materiallyDifferentFields,
            isEquivalent: materiallyDifferentFields.isEmpty
        )
    }

    /// Throws when two run summaries are not equivalent within the supplied tolerance.
    @discardableResult
    public static func assertEquivalent(
        baseline: BKRunSummary,
        candidate: BKRunSummary,
        tolerance: Double = 1e-9
    ) throws -> BKRunComparisonReport {
        let report = compareRuns(baseline: baseline, candidate: candidate, tolerance: tolerance)
        guard report.isEquivalent else {
            throw BKComparisonAssertionError(report: report)
        }
        return report
    }
}

public extension BKExportTool {
    /// Encodes a completed run into a portable export bundle.
    static func exportRunBundle(
        summary: BKRunSummary,
        trades: [BKTrade] = [],
        diagnostics: BKDiagnosticsSnapshotReport? = nil,
        scenario: BKScenarioConfig? = nil,
        prettyPrinted: Bool = true
    ) -> Result<BKRunExportBundle, BKExportError> {
        switch toJSON(summary, prettyPrinted: prettyPrinted) {
        case .failure(let error):
            return .failure(error)
        case .success(let summaryJSON):
            let diagnosticsSummaryJSON: String?
            if let diagnostics {
                switch toJSON(diagnostics, prettyPrinted: prettyPrinted) {
                case .success(let output):
                    diagnosticsSummaryJSON = output
                case .failure(let error):
                    return .failure(error)
                }
            } else {
                diagnosticsSummaryJSON = nil
            }

            let scenarioJSON: String?
            if let scenario {
                switch toJSON(scenario, prettyPrinted: prettyPrinted) {
                case .success(let output):
                    scenarioJSON = output
                case .failure(let error):
                    return .failure(error)
                }
            } else {
                scenarioJSON = nil
            }

            let tradesCSV: String?
            if trades.isEmpty {
                tradesCSV = nil
            } else {
                switch tradesToCSV(trades) {
                case .success(let output):
                    tradesCSV = output
                case .failure(let error):
                    return .failure(error)
                }
            }

            return .success(
                BKRunExportBundle(
                    summaryJSON: summaryJSON,
                    diagnosticsSummaryJSON: diagnosticsSummaryJSON,
                    tradesCSV: tradesCSV,
                    scenarioJSON: scenarioJSON
                )
            )
        }
    }

    /// Encodes a completed additive portfolio run into portable JSON/CSV artifacts.
    static func exportPortfolioRunBundle(
        _ report: BKPortfolioRunReport,
        prettyPrinted: Bool = true
    ) -> Result<BKPortfolioExportBundle, BKExportError> {
        switch toJSON(report, prettyPrinted: prettyPrinted) {
        case .failure(let error):
            return .failure(error)
        case .success(let portfolioJSON):
            let weightsCSV = portfolioWeightsToCSV(report.sleeveReports)
            let failuresJSON: String?
            if report.failures.isEmpty {
                failuresJSON = nil
            } else {
                switch toJSON(report.failures, prettyPrinted: prettyPrinted) {
                case .success(let output):
                    failuresJSON = output
                case .failure(let error):
                    return .failure(error)
                }
            }

            let rebalanceJSON: String?
            if report.rebalanceEvents.isEmpty {
                rebalanceJSON = nil
            } else {
                switch toJSON(report.rebalanceEvents, prettyPrinted: prettyPrinted) {
                case .success(let output):
                    rebalanceJSON = output
                case .failure(let error):
                    return .failure(error)
                }
            }

            return .success(
                BKPortfolioExportBundle(
                    portfolioJSON: portfolioJSON,
                    weightsCSV: weightsCSV,
                    failuresJSON: failuresJSON,
                    rebalanceJSON: rebalanceJSON
                )
            )
        }
    }

    /// Exports a compact run summary as human-readable Markdown.
    static func exportMarkdownSummary(
        _ summary: BKRunSummary,
        title: String? = nil
    ) -> Result<String, BKExportError> {
        let heading = title ?? "\(summary.symbol) Backtest Summary"
        let percentStyle = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(2))
        let ratioStyle = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(4))

        let dateRange: String = {
            switch (summary.startDate, summary.endDate) {
            case let (.some(start), .some(end)):
                return "\(start.ISO8601Format()) -> \(end.ISO8601Format())"
            case let (.some(start), nil):
                return "\(start.ISO8601Format()) -> n/a"
            case let (nil, .some(end)):
                return "n/a -> \(end.ISO8601Format())"
            default:
                return "n/a"
            }
        }()

        let markdown = """
        # \(heading)

        - Symbol: `\(summary.symbol)`
        - Bar count: \(summary.barCount)
        - Date range: \(dateRange)
        - Trades: \(summary.metrics.tradeCount)
        - Win rate: \((summary.metrics.winRate * 100.0).formatted(percentStyle))%
        - Total return: \((summary.metrics.totalReturn * 100.0).formatted(percentStyle))%
        - Annualized return: \((summary.metrics.annualizedReturn * 100.0).formatted(percentStyle))%
        - Max drawdown: \((summary.metrics.maxDrawdown * 100.0).formatted(percentStyle))%
        - Sharpe ratio: \(summary.metrics.sharpeRatio.formatted(ratioStyle))
        - Profit factor: \(summary.metrics.profitFactor.formatted(ratioStyle))
        """

        return .success(markdown)
    }

    /// Exports an additive portfolio run as human-readable Markdown.
    static func exportPortfolioMarkdownSummary(
        _ report: BKPortfolioRunReport,
        title: String? = nil
    ) -> Result<String, BKExportError> {
        guard let summary = report.summary else {
            return .failure(.emptyData("portfolio-summary"))
        }

        let heading = title ?? "\(report.portfolioID) Portfolio Summary"
        let percentStyle = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(2))
        let ratioStyle = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(4))
        let sleeveLines = report.sleeveReports.map { sleeve in
            let totalReturn = ((sleeve.summary?.metrics.totalReturn ?? 0) * 100.0).formatted(percentStyle)
            return "- `\(sleeve.symbol)` • status: \(sleeve.status.rawValue) • weight: \((sleeve.resolvedWeight * 100.0).formatted(percentStyle))% • return: \(totalReturn)%"
        }.joined(separator: "\n")

        let markdown = """
        # \(heading)

        - Portfolio: `\(report.portfolioID)`
        - Sleeves succeeded: \(report.succeededSleeveCount)
        - Sleeves failed: \(report.failedSleeveCount)
        - Trades: \(summary.metrics.tradeCount)
        - Win rate: \((summary.metrics.winRate * 100.0).formatted(percentStyle))%
        - Total return: \((summary.metrics.totalReturn * 100.0).formatted(percentStyle))%
        - Annualized return: \((summary.metrics.annualizedReturn * 100.0).formatted(percentStyle))%
        - Max drawdown: \((summary.metrics.maxDrawdown * 100.0).formatted(percentStyle))%
        - Sharpe ratio: \(summary.metrics.sharpeRatio.formatted(ratioStyle))
        - Profit factor: \(summary.metrics.profitFactor.formatted(ratioStyle))
        - Rebalance events: \(report.rebalanceEvents.count)

        ## Sleeves

        \(sleeveLines)
        """

        return .success(markdown)
    }
}

private func portfolioWeightsToCSV(_ sleeveReports: [BKPortfolioSleeveRunReport]) -> String {
    var lines = [
        "symbol,preset,status,requestedWeight,resolvedWeight,tradeCount,totalReturn,annualizedReturn,maxDrawdown,sharpeRatio"
    ]
    lines.reserveCapacity(sleeveReports.count + 1)

    for report in sleeveReports {
        let fields: [String] = [
            report.symbol,
            report.preset.rawValue,
            report.status.rawValue,
            report.requestedWeight.map { String($0) } ?? "",
            String(report.resolvedWeight),
            String(report.summary?.metrics.tradeCount ?? 0),
            String(report.summary?.metrics.totalReturn ?? 0),
            String(report.summary?.metrics.annualizedReturn ?? 0),
            String(report.summary?.metrics.maxDrawdown ?? 0),
            String(report.summary?.metrics.sharpeRatio ?? 0),
        ]
        lines.append(fields.map(bkEscapePortfolioCSVValue).joined(separator: ","))
    }

    return lines.joined(separator: "\n")
}

private func bkEscapePortfolioCSVValue(_ value: String) -> String {
    if value.contains(",") || value.contains("\"") || value.contains("\n") {
        return "\"\(value.replacing("\"", with: "\"\""))\""
    }
    return value
}

public extension BKScenarioTool {
    /// Default deterministic scenario matrix used for smoke-test workflows.
    static func defaultSmokeConfigs() -> [BKScenarioConfig] {
        [
            BKScenarioConfig(symbol: "SCENARIO_SMA_BASE", barCount: 64, driftPerBar: 0.0004, volatility: 0.01, seed: 42, strategy: .smaCrossover),
            BKScenarioConfig(symbol: "SCENARIO_EMA_TREND", barCount: 96, driftPerBar: 0.0007, volatility: 0.012, seed: 7, strategy: .emaFastSlow),
            BKScenarioConfig(symbol: "SCENARIO_SMA_VOL", barCount: 80, driftPerBar: 0.0002, volatility: 0.02, seed: 99, strategy: .smaCrossover),
        ]
    }

    /// Validates synthetic scenario config values before generation.
    static func validate(config: BKScenarioConfig) -> BKScenarioReadinessReport {
        var issues: [BKValidationIssue] = []

        if config.symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(
                BKValidationIssue(
                    code: "scenario_symbol_empty",
                    field: "symbol",
                    message: "Scenario symbol must not be empty.",
                    severity: .error
                )
            )
        }
        if config.barCount < 2 {
            issues.append(
                BKValidationIssue(
                    code: "scenario_bar_count_too_small",
                    field: "barCount",
                    message: "Scenario barCount must be at least 2.",
                    severity: .error
                )
            )
        }
        if config.startingPrice <= 0 {
            issues.append(
                BKValidationIssue(
                    code: "scenario_starting_price_invalid",
                    field: "startingPrice",
                    message: "Scenario startingPrice must be greater than 0.",
                    severity: .error
                )
            )
        }
        if config.volatility < 0 {
            issues.append(
                BKValidationIssue(
                    code: "scenario_volatility_negative",
                    field: "volatility",
                    message: "Scenario volatility must be non-negative.",
                    severity: .error
                )
            )
        }

        let validation = BKValidationReport(
            isValid: !issues.contains(where: { $0.severity == .error }),
            issues: issues
        )

        return BKScenarioReadinessReport(
            config: config,
            validation: validation,
            isReady: validation.isValid
        )
    }

    /// Runs a deterministic scenario and packages the result as a compact summary.
    static func summarize(config: BKScenarioConfig) -> BKRunSummary {
        let scenario = run(config: config)
        return BacktestingKitManager().buildSummary(
            symbol: config.symbol,
            candles: scenario.candles,
            result: scenario.backtest
        )
    }

    /// Runs a deterministic scenario and exports summary-oriented artifacts.
    static func runExportBundle(
        config: BKScenarioConfig,
        diagnostics: BKDiagnosticsSnapshotReport? = nil,
        prettyPrinted: Bool = true
    ) -> Result<BKRunExportBundle, BKExportError> {
        let scenario = run(config: config)
        let summary = BacktestingKitManager().buildSummary(
            symbol: config.symbol,
            candles: scenario.candles,
            result: scenario.backtest
        )
        let exportedTrades = scenario.backtest.trades.map(makeExportTrade)
        return BKExportTool.exportRunBundle(
            summary: summary,
            trades: exportedTrades,
            diagnostics: diagnostics,
            scenario: config,
            prettyPrinted: prettyPrinted
        )
    }

    /// Runs a deterministic smoke suite across one or more scenario configs.
    static func smokeSuite(
        configs: [BKScenarioConfig] = defaultSmokeConfigs()
    ) -> BKScenarioSmokeSuiteReport {
        let caseReports = configs.map { config in
            let readiness = validate(config: config)
            let summary = readiness.isReady ? summarize(config: config) : nil
            return BKScenarioSmokeCaseReport(config: config, readiness: readiness, summary: summary)
        }

        let passedCaseCount = caseReports.filter { $0.readiness.isReady && $0.summary != nil }.count
        let failedCaseCount = caseReports.count - passedCaseCount

        return BKScenarioSmokeSuiteReport(
            cases: caseReports,
            passedCaseCount: passedCaseCount,
            failedCaseCount: failedCaseCount,
            isSuccessful: failedCaseCount == 0
        )
    }

    private static func makeExportTrade(from trade: Trade) -> BKTrade {
        let exitTime = trade.exitDate ?? trade.entryDate
        let exitPrice = trade.exitPrice ?? trade.entryPrice
        let profit = exitPrice - trade.entryPrice
        let holdingPeriod = max(
            0,
            Calendar.current.dateComponents([.day], from: trade.entryDate, to: exitTime).day ?? 0
        )

        return BKTrade(
            direction: trade.type == .buy ? .long : .short,
            entryTime: trade.entryDate,
            entryPrice: trade.entryPrice,
            exitTime: exitTime,
            exitPrice: exitPrice,
            profit: profit,
            profitPct: trade.entryPrice == 0 ? 0 : (profit / trade.entryPrice) * 100,
            growth: trade.entryPrice == 0 ? 0 : exitPrice / trade.entryPrice,
            holdingPeriod: holdingPeriod,
            exitReason: "scenario"
        )
    }
}
