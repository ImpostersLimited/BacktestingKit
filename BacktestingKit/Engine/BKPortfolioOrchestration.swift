import Foundation

public extension BKEngine {
    /// Runs a preset-backed additive portfolio workflow and returns aggregate plus sleeve-level output.
    static func runPortfolio(
        _ request: PortfolioRequest,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> BKPortfolioRunReport {
        let portfolioID = normalizedPortfolioID(request.portfolioID)
        guard !request.sleeves.isEmpty else {
            let failure = makePortfolioValidationFailure(
                instrumentID: portfolioID,
                stage: "portfolio-validation",
                message: "Portfolio request must contain at least one sleeve."
            )
            return BKPortfolioRunReport(
                portfolioID: portfolioID,
                allocation: request.allocation,
                rebalancePolicy: request.rebalancePolicy,
                sleeveReports: [],
                failures: [failure],
                succeededSleeveCount: 0,
                failedSleeveCount: 0,
                isPartialSuccess: false,
                isSuccessful: false
            )
        }

        let duplicateSymbols = duplicateSleeveSymbols(in: request.sleeves)
        guard duplicateSymbols.isEmpty else {
            let failure = makePortfolioValidationFailure(
                instrumentID: portfolioID,
                stage: "portfolio-validation",
                message: "Portfolio sleeve symbols must be unique.",
                metadata: ["duplicates": duplicateSymbols.joined(separator: ",")]
            )
            return BKPortfolioRunReport(
                portfolioID: portfolioID,
                allocation: request.allocation,
                rebalancePolicy: request.rebalancePolicy,
                sleeveReports: [],
                failures: [failure],
                succeededSleeveCount: 0,
                failedSleeveCount: 0,
                isPartialSuccess: false,
                isSuccessful: false
            )
        }

        var sleeveReports: [BKPortfolioSleeveRunReport] = []
        sleeveReports.reserveCapacity(request.sleeves.count)

        var successfulContexts: [Int: BKPortfolioSuccessfulSleeveContext] = [:]
        var failures: [BKEngineFailure] = []

        for (index, sleeve) in request.sleeves.enumerated() {
            let run = preflightAndRunCSV(
                symbol: sleeve.symbol,
                csv: sleeve.csv,
                preset: sleeve.preset,
                dateFormat: sleeve.dateFormat,
                reverse: sleeve.reverse,
                columnMapping: sleeve.columnMapping,
                log: log
            )

            if let summary = run.summary,
               let bars = try? successfulPortfolioBars(for: sleeve) {
                let context = BKPortfolioSuccessfulSleeveContext(
                    summary: summary,
                    annualizedVolatility: annualizedVolatility(from: bars),
                    momentumScore: summary.metrics.totalReturn
                )
                successfulContexts[index] = context
                sleeveReports.append(
                    BKPortfolioSleeveRunReport(
                        symbol: sleeve.symbol,
                        preset: sleeve.preset,
                        status: .succeeded,
                        requestedWeight: sleeve.targetWeight,
                        annualizedVolatility: context.annualizedVolatility,
                        momentumScore: context.momentumScore,
                        summary: summary
                    )
                )
            } else {
                let failure = run.failure
                    ?? makePortfolioValidationFailure(
                        instrumentID: sleeve.symbol,
                        stage: "portfolio-sleeve-run",
                        message: "Sleeve execution did not produce a summary."
                    )
                failures.append(failure)
                sleeveReports.append(
                    BKPortfolioSleeveRunReport(
                        symbol: sleeve.symbol,
                        preset: sleeve.preset,
                        status: .failed,
                        requestedWeight: sleeve.targetWeight,
                        failure: failure
                    )
                )
                if !request.continueOnFailure {
                    return finalizePortfolioRun(
                        portfolioID: portfolioID,
                        allocation: request.allocation,
                        rebalancePolicy: request.rebalancePolicy,
                        sleeveReports: sleeveReports,
                        successfulContexts: successfulContexts,
                        failures: failures,
                        requestLevelFailures: []
                    )
                }
            }
        }

        let weightResolution = resolvePortfolioWeights(
            request: request,
            sleeveReports: sleeveReports,
            successfulContexts: successfulContexts
        )
        failures.append(contentsOf: weightResolution.failures)

        let updatedSleeves = sleeveReports.enumerated().map { index, sleeveReport in
            var updated = sleeveReport
            updated.resolvedWeight = weightResolution.weights[index]
            return updated
        }

        return finalizePortfolioRun(
            portfolioID: portfolioID,
            allocation: request.allocation,
            rebalancePolicy: request.rebalancePolicy,
            sleeveReports: updatedSleeves,
            successfulContexts: successfulContexts,
            failures: failures,
            requestLevelFailures: weightResolution.failures
        )
    }
}

private struct BKPortfolioSuccessfulSleeveContext {
    let summary: BKRunSummary
    let annualizedVolatility: Double
    let momentumScore: Double
}

private struct BKPortfolioWeightResolution {
    let weights: [Double]
    let failures: [BKEngineFailure]
}

private func normalizedPortfolioID(_ portfolioID: String) -> String {
    let trimmed = portfolioID.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "PORTFOLIO" : trimmed
}

private func duplicateSleeveSymbols(in sleeves: [BKPortfolioSleeveRequest]) -> [String] {
    var seen: Set<String> = []
    var duplicates: Set<String> = []

    for sleeve in sleeves {
        let symbol = sleeve.symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        if seen.contains(symbol) {
            duplicates.insert(symbol)
        } else {
            seen.insert(symbol)
        }
    }

    return duplicates.sorted()
}

private func successfulPortfolioBars(for sleeve: BKPortfolioSleeveRequest) throws -> [BKBar] {
    switch BKQuickDemo.parseBars(
        csv: sleeve.csv,
        dateFormat: sleeve.dateFormat,
        reverse: sleeve.reverse,
        columnMapping: sleeve.columnMapping
    ) {
    case .success(let bars):
        return bars
    case .failure(let error):
        throw error
    }
}

private func annualizedVolatility(from bars: [BKBar]) -> Double {
    guard bars.count > 2 else { return 0 }

    let closes = bars.map(\.close)
    let returns = zip(closes, closes.dropFirst()).compactMap { previous, current -> Double? in
        guard previous > 0, current > 0 else { return nil }
        return (current / previous) - 1.0
    }

    guard returns.count > 1 else { return 0 }

    let mean = returns.reduce(0, +) / Double(returns.count)
    let variance = returns.reduce(0) { partial, value in
        let delta = value - mean
        return partial + (delta * delta)
    } / Double(returns.count - 1)

    return sqrt(max(variance, 0)) * sqrt(252)
}

private func resolvePortfolioWeights(
    request: BKPortfolioRequest,
    sleeveReports: [BKPortfolioSleeveRunReport],
    successfulContexts: [Int: BKPortfolioSuccessfulSleeveContext]
) -> BKPortfolioWeightResolution {
    let count = sleeveReports.count
    guard count > 0 else {
        return BKPortfolioWeightResolution(weights: [], failures: [])
    }

    var failures: [BKEngineFailure] = []
    let successIndices = Set(successfulContexts.keys)

    func normalizedSuccessfulWeights(from rawWeights: [Double]) -> [Double] {
        var filtered = rawWeights.enumerated().map { index, weight -> Double in
            guard successIndices.contains(index) else { return 0 }
            return max(weight, 0)
        }

        let total = filtered.reduce(0, +)
        guard total > 0 else {
            let equalWeight = successIndices.isEmpty ? 0 : 1.0 / Double(successIndices.count)
            return filtered.enumerated().map { index, _ in
                successIndices.contains(index) ? equalWeight : 0
            }
        }

        for index in filtered.indices {
            filtered[index] /= total
        }
        return filtered
    }

    let rawWeights: [Double]
    switch request.allocation.mode {
    case .explicit:
        guard let explicitWeights = request.allocation.explicitWeights,
              explicitWeights.count == count else {
            failures.append(
                makePortfolioValidationFailure(
                    instrumentID: normalizedPortfolioID(request.portfolioID),
                    stage: "portfolio-allocation",
                    message: "Explicit portfolio weights must match the sleeve count.",
                    metadata: [
                        "sleeveCount": String(count),
                        "weightCount": String(request.allocation.explicitWeights?.count ?? 0),
                    ]
                )
            )
            rawWeights = Array(repeating: 0, count: count)
            break
        }
        rawWeights = explicitWeights

    case .sleeveWeights:
        rawWeights = sleeveReports.map { $0.requestedWeight ?? 0 }

    case .riskParity:
        let volatilities = sleeveReports.enumerated().map { index, report -> Double in
            guard successIndices.contains(index) else { return 0 }
            return successfulContexts[index]?.annualizedVolatility ?? 0
        }
        rawWeights = BKPortfolioPresets.riskParityWeights(annualizedVolatilities: volatilities)

    case .riskOnRiskOff:
        let riskOnIndex = request.allocation.riskOnIndex ?? 0
        let riskOffIndex = request.allocation.riskOffIndex ?? 1
        guard riskOnIndex >= 0,
              riskOnIndex < count,
              riskOffIndex >= 0,
              riskOffIndex < count,
              riskOnIndex != riskOffIndex else {
            failures.append(
                makePortfolioValidationFailure(
                    instrumentID: normalizedPortfolioID(request.portfolioID),
                    stage: "portfolio-allocation",
                    message: "Risk-on / risk-off allocation requires two distinct valid sleeve indices."
                )
            )
            rawWeights = Array(repeating: 0, count: count)
            break
        }

        let riskOnMomentum = successfulContexts[riskOnIndex]?.momentumScore ?? 0
        let riskOffMomentum = successfulContexts[riskOffIndex]?.momentumScore ?? 0
        let pairWeights = BKPortfolioPresets.riskOnRiskOffWeights(
            riskOnMomentum: riskOnMomentum,
            riskOffMomentum: riskOffMomentum
        )

        var working = Array(repeating: 0.0, count: count)
        working[riskOnIndex] = successIndices.contains(riskOnIndex) ? pairWeights[0] : 0
        working[riskOffIndex] = successIndices.contains(riskOffIndex) ? pairWeights[1] : 0
        rawWeights = working
    }

    return BKPortfolioWeightResolution(
        weights: normalizedSuccessfulWeights(from: rawWeights),
        failures: failures
    )
}

private func finalizePortfolioRun(
    portfolioID: String,
    allocation: BKPortfolioAllocationInput,
    rebalancePolicy: BKPortfolioRebalancePolicy,
    sleeveReports: [BKPortfolioSleeveRunReport],
    successfulContexts: [Int: BKPortfolioSuccessfulSleeveContext],
    failures: [BKEngineFailure],
    requestLevelFailures: [BKEngineFailure]
) -> BKPortfolioRunReport {
    let succeededSleeveCount = sleeveReports.filter { $0.status == .succeeded }.count
    let failedSleeveCount = sleeveReports.filter { $0.status == .failed }.count

    guard succeededSleeveCount > 0 else {
        return BKPortfolioRunReport(
            portfolioID: portfolioID,
            allocation: allocation,
            rebalancePolicy: rebalancePolicy,
            sleeveReports: sleeveReports,
            failures: failures,
            succeededSleeveCount: succeededSleeveCount,
            failedSleeveCount: failedSleeveCount,
            isPartialSuccess: false,
            isSuccessful: false
        )
    }

    guard requestLevelFailures.isEmpty else {
        return BKPortfolioRunReport(
            portfolioID: portfolioID,
            allocation: allocation,
            rebalancePolicy: rebalancePolicy,
            sleeveReports: sleeveReports,
            failures: failures,
            succeededSleeveCount: succeededSleeveCount,
            failedSleeveCount: failedSleeveCount,
            isPartialSuccess: true,
            isSuccessful: false
        )
    }

    let successfulSleeves = sleeveReports.enumerated().compactMap { index, report -> BKPortfolioSleeveRunReport? in
        guard successfulContexts[index] != nil else { return nil }
        return report
    }

    let aggregateMetrics = aggregatePortfolioMetrics(from: successfulSleeves)
    let startDate = successfulSleeves.compactMap { $0.summary?.startDate }.min()
    let endDate = successfulSleeves.compactMap { $0.summary?.endDate }.max()
    let barCount = successfulSleeves.reduce(0) { partial, report in
        partial + (report.summary?.barCount ?? 0)
    }
    let rebalanceEvents = buildRebalanceEvents(
        policy: rebalancePolicy,
        startDate: startDate,
        endDate: endDate
    )

    let summary = BKRunSummary(
        symbol: portfolioID,
        barCount: barCount,
        startDate: startDate,
        endDate: endDate,
        metrics: aggregateMetrics
    )

    return BKPortfolioRunReport(
        portfolioID: portfolioID,
        allocation: allocation,
        rebalancePolicy: rebalancePolicy,
        summary: summary,
        sleeveReports: sleeveReports,
        rebalanceEvents: rebalanceEvents,
        failures: failures,
        succeededSleeveCount: succeededSleeveCount,
        failedSleeveCount: failedSleeveCount,
        isPartialSuccess: succeededSleeveCount > 0 && failedSleeveCount > 0,
        isSuccessful: true
    )
}

private func aggregatePortfolioMetrics(
    from sleeveReports: [BKPortfolioSleeveRunReport]
) -> BKRunHeadlineMetrics {
    let totalWeight = sleeveReports.reduce(0) { partial, report in
        partial + max(report.resolvedWeight, 0)
    }
    let normalizedReports: [(BKPortfolioSleeveRunReport, Double)] = sleeveReports.map { report in
        let normalizedWeight = totalWeight > 0 ? report.resolvedWeight / totalWeight : 0
        return (report, normalizedWeight)
    }

    let totalTrades = normalizedReports.reduce(0) { partial, pair in
        partial + (pair.0.summary?.metrics.tradeCount ?? 0)
    }
    let weightedWinRate: Double
    if totalTrades > 0 {
        weightedWinRate = normalizedReports.reduce(0) { partial, pair in
            let trades = pair.0.summary?.metrics.tradeCount ?? 0
            let wins = Double(trades) * (pair.0.summary?.metrics.winRate ?? 0)
            return partial + wins
        } / Double(totalTrades)
    } else {
        weightedWinRate = normalizedReports.reduce(0) { partial, pair in
            partial + ((pair.0.summary?.metrics.winRate ?? 0) * pair.1)
        }
    }

    return BKRunHeadlineMetrics(
        tradeCount: totalTrades,
        winRate: weightedWinRate,
        totalReturn: normalizedReports.reduce(0) { partial, pair in
            partial + ((pair.0.summary?.metrics.totalReturn ?? 0) * pair.1)
        },
        annualizedReturn: normalizedReports.reduce(0) { partial, pair in
            partial + ((pair.0.summary?.metrics.annualizedReturn ?? 0) * pair.1)
        },
        maxDrawdown: normalizedReports.reduce(0) { partial, pair in
            partial + ((pair.0.summary?.metrics.maxDrawdown ?? 0) * pair.1)
        },
        sharpeRatio: normalizedReports.reduce(0) { partial, pair in
            partial + ((pair.0.summary?.metrics.sharpeRatio ?? 0) * pair.1)
        },
        profitFactor: normalizedReports.reduce(0) { partial, pair in
            partial + ((pair.0.summary?.metrics.profitFactor ?? 0) * pair.1)
        }
    )
}

private func buildRebalanceEvents(
    policy: BKPortfolioRebalancePolicy,
    startDate: Date?,
    endDate: Date?
) -> [BKPortfolioRebalanceEvent] {
    guard let startDate, let endDate, startDate <= endDate else { return [] }

    switch policy.mode {
    case .none:
        return []

    case .manual:
        return policy.manualDates
            .filter { $0 >= startDate && $0 <= endDate }
            .sorted()
            .map { BKPortfolioRebalanceEvent(date: $0, source: "manual") }

    case .periodic:
        guard let frequency = policy.frequency else { return [] }
        var events: [BKPortfolioRebalanceEvent] = []
        let calendar = Calendar(identifier: .gregorian)
        var cursor = startDate

        while let next = nextRebalanceDate(
            after: cursor,
            frequency: frequency,
            calendar: calendar
        ), next <= endDate {
            events.append(
                BKPortfolioRebalanceEvent(
                    date: next,
                    source: "periodic:\(frequency.rawValue)"
                )
            )
            cursor = next
        }

        return events
    }
}

private func nextRebalanceDate(
    after date: Date,
    frequency: BKPortfolioRebalanceFrequency,
    calendar: Calendar
) -> Date? {
    switch frequency {
    case .weekly:
        return calendar.date(byAdding: .day, value: 7, to: date)
    case .monthly:
        return calendar.date(byAdding: .month, value: 1, to: date)
    case .quarterly:
        return calendar.date(byAdding: .month, value: 3, to: date)
    }
}

private func makePortfolioValidationFailure(
    instrumentID: String,
    stage: String,
    message: String,
    metadata: [String: String] = [:]
) -> BKEngineFailure {
    BKEngineFailure(
        instrumentID: instrumentID,
        code: .invalidInput,
        stage: stage,
        message: message,
        metadata: metadata
    )
}
