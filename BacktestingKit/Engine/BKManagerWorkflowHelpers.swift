import Foundation

public extension BacktestingKitManager {
    /// Parses inline CSV into candles and runs a stable built-in recipe.
    func parseAndRunRecipe(
        _ recipe: BKStrategyRecipe,
        csv: String,
        dateFormat: String = "yyyy-MM-dd",
        reverse: Bool = false,
        columnMapping: BKCSVColumnMapping? = nil
    ) -> Result<BacktestResult, Error> {
        switch BKQuickDemo.parseBars(
            csv: csv,
            dateFormat: dateFormat,
            reverse: reverse,
            columnMapping: columnMapping
        ) {
        case .success(let bars):
            let candles = BKQuickDemo.makeCandles(from: bars)
            return .success(runStrategyRecipe(recipe, candles: candles))
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Runs a stable built-in strategy recipe and returns the raw backtest result.
    func runStrategyRecipe(
        _ recipe: BKStrategyRecipe,
        candles: [Candlestick]
    ) -> BacktestResult {
        switch recipe {
        case .smaCrossover(let fast, let slow):
            return backtestSMACrossover(candles: candles, fast: fast, slow: slow)
        case .emaFastSlow(let fastPeriod, let slowPeriod, let atrPeriod, let atrStopMultiplier):
            return backtestEMAFastSlowWithATRStop(
                candles: candles,
                fastPeriod: fastPeriod,
                slowPeriod: slowPeriod,
                atrPeriod: atrPeriod,
                atrStopMultiplier: atrStopMultiplier
            )
        case .rsi2MeanReversion(let trendPeriod, let entryThreshold, let exitThreshold):
            return backtestRSI2MeanReversion(
                candles: candles,
                trendPeriod: trendPeriod,
                entryThreshold: entryThreshold,
                exitThreshold: exitThreshold
            )
        }
    }

    /// Runs a stable built-in strategy recipe and packages the result into a compact summary.
    func runStrategyRecipeSummary(
        _ recipe: BKStrategyRecipe,
        symbol: String,
        candles: [Candlestick]
    ) -> BKRunSummary {
        let result = runStrategyRecipe(recipe, candles: candles)
        return buildSummary(symbol: symbol, candles: candles, result: result)
    }

    /// Runs a stable built-in recipe and packages summary/report-oriented helper outputs.
    func runRecipeReport(
        _ recipe: BKStrategyRecipe,
        symbol: String,
        candles: [Candlestick],
        minimumAcceptableReturn: Double = 0
    ) -> BKStrategyRecipeReport {
        let result = runStrategyRecipe(recipe, candles: candles)
        let summary = buildSummary(symbol: symbol, candles: candles, result: result)
        let snapshot = buildReportSnapshot(from: result, candles: candles)
        let advancedMetrics = buildAdvancedPerformanceMetrics(
            from: result,
            candles: candles,
            minimumAcceptableReturn: minimumAcceptableReturn
        )

        return BKStrategyRecipeReport(
            recipe: recipe,
            symbol: symbol,
            result: result,
            summary: summary,
            snapshot: snapshot,
            advancedMetrics: advancedMetrics
        )
    }

    /// Applies a deterministic trend indicator bundle to a candle series.
    func applyTrendIndicatorBundle(
        candles: [Candlestick],
        smaPeriods: [Int],
        emaPeriods: [Int],
        keyNamespace: String
    ) -> BKIndicatorBundleResult {
        var enriched = candles
        var keys: [String] = []

        let normalizedSMA = Array(Set(smaPeriods.filter { $0 > 0 })).sorted()
        for period in normalizedSMA {
            let key = "sma_\(period)_\(keyNamespace)"
            enriched = simpleMovingAverage(enriched, period: period, name: key)
            keys.append(key)
        }

        let normalizedEMA = Array(Set(emaPeriods.filter { $0 > 0 })).sorted()
        let emaNamespace = "\(keyNamespace)_trend"
        for period in normalizedEMA {
            enriched = exponentialMovingAverage(enriched, period: period, uuid: emaNamespace)
            keys.append("ema_\(period)_\(emaNamespace)")
        }

        return BKIndicatorBundleResult(candles: enriched, appliedIndicatorKeys: keys)
    }

    /// Applies a deterministic momentum indicator bundle to a candle series.
    func applyMomentumIndicatorBundle(
        candles: [Candlestick],
        rsiPeriod: Int = 14,
        stochasticKPeriod: Int = 14,
        stochasticDPeriod: Int = 3,
        keyNamespace: String
    ) -> BKIndicatorBundleResult {
        var enriched = candles
        var keys: [String] = []

        let rsiNamespace = "\(keyNamespace)_momentum_rsi"
        enriched = relativeStrengthIndex(enriched, period: rsiPeriod, uuid: rsiNamespace)
        keys.append("rsi_\(rsiPeriod)_\(rsiNamespace)")

        let stochasticNamespace = "\(keyNamespace)_momentum_stoch"
        enriched = stochasticOscillator(
            enriched,
            kPeriod: stochasticKPeriod,
            dPeriod: stochasticDPeriod,
            uuid: stochasticNamespace
        )
        keys.append("stochK_\(stochasticKPeriod)_\(stochasticNamespace)")
        keys.append("stochD_\(stochasticDPeriod)_\(stochasticNamespace)")

        return BKIndicatorBundleResult(candles: enriched, appliedIndicatorKeys: keys)
    }

    /// Applies a deterministic volatility indicator bundle to a candle series.
    func applyVolatilityIndicatorBundle(
        candles: [Candlestick],
        atrPeriod: Int = 14,
        bollingerPeriod: Int = 20,
        bollingerStdDev: Double = 2,
        keyNamespace: String
    ) -> BKIndicatorBundleResult {
        var enriched = candles
        var keys: [String] = []

        let atrNamespace = "\(keyNamespace)_volatility_atr"
        enriched = averageTrueRange(enriched, period: atrPeriod, uuid: atrNamespace)
        keys.append("atr_\(atrPeriod)_\(atrNamespace)")

        let bollingerNamespace = "\(keyNamespace)_volatility_bb"
        enriched = bollingerBands(
            enriched,
            period: bollingerPeriod,
            numStdDev: bollingerStdDev,
            uuid: bollingerNamespace
        )
        keys.append("bbMiddle_\(bollingerPeriod)_\(bollingerNamespace)")
        keys.append("bbUpper_\(bollingerPeriod)_\(bollingerStdDev)_\(bollingerNamespace)")
        keys.append("bbLower_\(bollingerPeriod)_\(bollingerStdDev)_\(bollingerNamespace)")

        return BKIndicatorBundleResult(candles: enriched, appliedIndicatorKeys: keys)
    }

    /// Applies the package's default screening indicator bundle in one pass.
    func applyDefaultScreeningBundle(
        candles: [Candlestick],
        keyNamespace: String = "screening"
    ) -> BKIndicatorBundleResult {
        let trend = applyTrendIndicatorBundle(
            candles: candles,
            smaPeriods: [20, 50, 200],
            emaPeriods: [12, 26],
            keyNamespace: keyNamespace
        )
        let momentum = applyMomentumIndicatorBundle(
            candles: trend.candles,
            rsiPeriod: 14,
            stochasticKPeriod: 14,
            stochasticDPeriod: 3,
            keyNamespace: keyNamespace
        )
        let volatility = applyVolatilityIndicatorBundle(
            candles: momentum.candles,
            atrPeriod: 14,
            bollingerPeriod: 20,
            bollingerStdDev: 2,
            keyNamespace: keyNamespace
        )

        return BKIndicatorBundleResult(
            candles: volatility.candles,
            appliedIndicatorKeys: trend.appliedIndicatorKeys + momentum.appliedIndicatorKeys + volatility.appliedIndicatorKeys
        )
    }

    /// Builds app-facing headline metrics from an existing backtest result.
    func buildHeadlineMetrics(from result: BacktestResult) -> BKRunHeadlineMetrics {
        BKRunHeadlineMetrics(result: result)
    }

    /// Builds a compact app-facing summary from candles and an existing result.
    func buildSummary(
        symbol: String,
        candles: [Candlestick],
        result: BacktestResult
    ) -> BKRunSummary {
        BKRunSummary(
            symbol: symbol,
            barCount: candles.count,
            startDate: candles.first?.date,
            endDate: candles.last?.date,
            metrics: buildHeadlineMetrics(from: result)
        )
    }

    /// Builds a compact report snapshot from an existing backtest result.
    func buildReportSnapshot(from result: BacktestResult, candles: [Candlestick]) -> BKManagerReportSnapshot {
        let report = buildMetricsReport(from: result, candles: candles)
        return buildReportSnapshot(from: report)
    }

    /// Builds a compact report snapshot from an existing metrics report.
    func buildReportSnapshot(from report: BacktestMetricsReport) -> BKManagerReportSnapshot {
        BKManagerReportSnapshot(report: report)
    }

    /// Builds advanced performance metrics from an existing backtest result.
    func buildAdvancedPerformanceMetrics(
        from result: BacktestResult,
        candles: [Candlestick],
        minimumAcceptableReturn: Double = 0
    ) -> BKAdvancedPerformanceMetrics {
        let report = buildMetricsReport(from: result, candles: candles)
        return advancedPerformanceMetrics(
            report: report,
            candles: candles,
            minimumAcceptableReturn: minimumAcceptableReturn
        )
    }

    /// Runs an SMA crossover workflow and packages the outcome into a summary.
    func runSMACrossoverSummary(
        symbol: String,
        candles: [Candlestick],
        fast: Int = 5,
        slow: Int = 20
    ) -> BKRunSummary {
        let result = backtestSMACrossover(candles: candles, fast: fast, slow: slow)
        return buildSummary(symbol: symbol, candles: candles, result: result)
    }

    /// Runs the built-in EMA fast/slow workflow and packages the outcome into a summary.
    func runEMAFastSlowSummary(
        symbol: String,
        candles: [Candlestick],
        fastPeriod: Int = 12,
        slowPeriod: Int = 26
    ) -> BKRunSummary {
        let result = backtestEMAFastSlowWithATRStop(
            candles: candles,
            fastPeriod: fastPeriod,
            slowPeriod: slowPeriod
        )
        return buildSummary(symbol: symbol, candles: candles, result: result)
    }
}
