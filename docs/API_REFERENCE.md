# API Reference

This document explains the public API surface of BacktestingKit, grouped by component.
All runtime entrypoints are **Result-based** (`Result<Success, Failure>`) and avoid public `throws`.

## 1) Engine Entrypoints

## `BKEngine`

`BKEngine` is the canonical top-level surface for app integration.

- `runV3(_:)`
  Runs one instrument through the v3 pipeline (data fetch, parse, strategy simulation, persistence).
- `runV2(_:)`
  Runs one instrument through v2-compatible simulation.
- `runDemo(dataset:csv:log:)`
  Runs offline bundled demo data and returns a summary suitable for UI preview.
- `runPreset(dataset:preset:log:)`
  Runs a bundled dataset through one of the stable preset workflows and returns `BKRunSummary`.
- `runPresetCSV(symbol:csv:preset:dateFormat:reverse:columnMapping:log:)`
  Runs inline CSV through a preset-backed workflow without defining a provider or building candles manually.
- `preflightAndRunCSV(symbol:csv:preset:dateFormat:reverse:columnMapping:log:)`
  Bundles CSV preflight validation and preset execution into one structured helper report.
- `runScenario(config:)`
  Runs a deterministic synthetic scenario and returns a compact `BKRunSummary`.
- `summarize(symbol:bars:result:)`
  Builds a compact `BKRunSummary` from parsed bars and an existing `BacktestResult`.
- `summarize(symbol:candles:result:)`
  Builds the same summary from candles.
- `runDemoCSV(symbol:csv:fast:slow:log:)`
  Executes the built-in SMA crossover workflow directly from inline CSV.
- `runV2CSV(...)` / `runV3CSV(...)`
  Execute v2/v3 flows from inline CSV without defining a custom provider.
- `runV2ValidatedCSV(...)` / `runV3ValidatedCSV(...)`
  Bundle CSV preflight, request validation, and engine execution into one app-facing report payload.
- `makeV3Driver` / `makeV2Driver`
  Injectable driver builders used to override internals in tests or custom setups.

## `BKEngineOneLiner`

Single-call API layer intended for concise app code and Playground usage.

- `BKV3Request`
  Input envelope for one-instrument v3 runs (instrument, parser/execution options, providers, logging).
- `BKV2Request`
  Input envelope for one-instrument v2 runs.
- `runBKV3(_:)` / `runBKV2(_:)`
  Primary one-liner execution functions.
- `runBKV3CSV(...)` / `runBKV2CSV(...)`
  Inline-CSV convenience wrappers around the canonical `BKEngine` CSV helper paths.
- `runV3(_:)`, `runV2(_:)`, `runATV3(_:)`, `runATV2(_:)`
  Compatibility aliases to support migration from older naming.

## 2) Component Graph and POP Composition

## `BKSimulationDriverFactory`

Protocol defining how simulation drivers are instantiated.

- `makeV3Driver(dataStore:csvProvider:)`
- `makeV2Driver(csvProvider:)`

Use this protocol to swap in custom driver implementations without changing call sites.

## `BKDefaultSimulationDriverFactory`

Default factory implementation creating:

- `BKSimulationDriver` for v3
- `BKV2SimulationDriver` for v2

## `BKEngineComponentGraph`

Single source of truth for injectable engine components.
Current public component:

- `simulationFactory: any BKSimulationDriverFactory`

## 3) Demo API

## `BKQuickDemoDataset`

Enum of bundled offline datasets (10y/1d samples across large-cap US symbols).

- `symbol` and `exchange` computed metadata are intended for UI labeling.

## `BKQuickDemoError`

Demo-specific failures:

- Missing bundled CSV resource
- Parsed-but-empty dataset

## `BKQuickDemoSummary`

Compact summary for demo execution:

- symbol
- bar count
- date range
- `BacktestResult`

## `BKQuickDemo`

- `runBundledSMACrossoverDemo(dataset:csv:log:)`
  Executes SMA(5/20) crossover on bundled or caller-provided CSV.
- `loadBundledCSV(dataset:)`
  Loads bundled CSV text for a demo dataset.
- `parseBars(csv:dateFormat:reverse:columnMapping:)`
  Parses demo CSV into chronological bars with strict failure handling.
- `makeCandles(from:)`
  Converts bars into candles for manager-owned workflows.
- `summarize(symbol:bars:result:)`
  Builds a `BKRunSummary` from a completed demo workflow.
- `runBundledPresetDemo(dataset:preset:log:)`
  Runs a bundled dataset through a preset-backed workflow and returns `BKRunSummary`.
- `runBundledSmokeMatrix(datasets:preset:log:)`
  Executes one preset across multiple bundled datasets for deterministic smoke testing.
- `runAAPL10Y1DSMACrossover(csv:log:)`
  AAPL convenience wrapper.

Compatibility typealias:

- `BKDemoDataset = BKQuickDemoDataset`

## 4) Simulation Driver Contracts

## Driver Protocols

## `BKV2SimulationDriving`

- `simulateInstrument(...) -> Result<(BKV2.SimulateConfigOutput, PositionStatus), BKEngineFailure>`

## `BKV3SimulationDriving`

- `simulateInstrumentDetailed(...) -> Result<BKSimulationInstrumentReport, BKEngineFailure>`
- protocol extension:
  - `simulateInstrument(...) -> Result<Void, BKEngineFailure>`

## v3 Driver (`BKSimulationDriver`)

Core responsibilities:

- Load CSV from provider
- Parse bars (legacy/streaming/strict modes)
- Load configs and rules
- Execute simulation
- Persist config/analysis/trades/risks
- Emit batch reports/progress

Key APIs:

- `simulateInstrument(...)`
- `simulateInstrumentAdvanced(...)`
- `simulateInstrumentDetailed(...)`
- `simulateInstruments(...)`
- `simulateInstrumentsCollectingFailures(...)`
- `simulateInstrumentsWithReport(...)`
- `simulateInstrumentsWithDetailedReport(...)`
- `startSimulationBatch(...)`

Associated result/report types:

- `BKSimulationInstrumentReport`
- `BKSimulationBatchOptions`
- `BKSimulationExecutionOptions`
- `BKCSVParserMode`
- `BKSimulationProgress`
- `BKSimulationBatchReport`
- `BKSimulationBatchDetailedReport`
- `BKSimulationBatchRunHandle`

Failure model:

- `BKSimulationDriverError` (input/concurrency/empty-bars validation)
- `BKSimulationRunFailure` (per-instrument batch failure)
- `BKEngineFailure` (typed UI-facing failure payload)
- `BKEngineErrorCode` (error category)

## v2 Driver (`BKV2SimulationDriver`)

Runs one v2 instrument/config pair against parsed bars and returns:

- simulation output
- terminal position status

## 5) Data Ingestion and Providers

## Parsing

## `BKBarParsing`

Protocol for CSV-to-bar parsers:

- parse with `BKSimulationExecutionOptions`
- parse with explicit column mapping

Both return `Result<[BKBar], BKCSVParsingError>`.

## `BKCSVBarParser`

Default parser implementation supporting:

- legacy parser mode
- streaming lenient mode
- streaming strict mode

## CSV helper functions

- `csvToBars(...)`
- `csvToBarsStreaming(...)`

Both enforce:

- ISO8601-compatible date parsing
- chronological order validation
- configurable OHLCV(+adjusted close) column mapping

## Parsing error model

## `BKCSVParsingError`

Typed CSV parse failures including:

- missing header/columns
- invalid ISO8601 date
- malformed row
- invalid numeric field
- non-chronological row order

## Provider abstractions

## `BKRawCsvProvider`

Protocol for any raw CSV source.

- `getRawCsv(ticker:p1:p2:) -> Result<String, Error>`

## `BKCustomCsvProvider`

Closure-backed provider for app-controlled data pipelines.

## `BKInlineCsvProvider`

Public provider that always returns the caller-supplied CSV string. Intended for helper workflows and tests.

## `BKCachedCsvProvider`

Decorator adding in-memory LRU-like/TTL caching and metrics around another provider.

## Cache types

- `BKCsvCacheConfiguration`
  cache capacity + TTL.
- `BKCsvCacheStats`
  hits/misses/entries + hitRate.
- `BKCacheMetricsSnapshot`
  timestamped cache stats snapshot.

## Cache metrics POP protocols

- `BKCacheMetricsReporting`
- `BKCacheMetricsSnapshotStoring`

Concrete types:

- `BKCacheMetricsReporter`
- `BKCacheMetricsHistory`

## AlphaVantage provider

## `AlphaVantageClient`

Network CSV provider with retry/rate-limiting support.

- `getRawCsv(...)`
- `getInstrumentDetail(...)`

Support types:

- `AlphaVantageClientError`
- `AlphaVantageRetryPolicy`
- `BKRequestRateLimiter`

## Data Store contract

## `BKV3DataStore`

Persistence abstraction for v3 simulation artifacts (configs/rules/analysis/trades/risks), all Result-based async methods.

## 6) Core Backtest Runtime

## Primary runtime models/functions (`Analysis/BKBacktestCore.swift`)

- `BKBar`
  canonical OHLCV(+optional adjusted close) bar.

## 7) Helper Workflow Models

App/demo-oriented helper models:

- `BKRunHeadlineMetrics`
  Compact headline metrics derived from `BacktestResult` or v2 analysis output.
- `BKRunSummary`
  Symbol, bar count, date range, and headline metrics for UI and export workflows.
- `BKAppPresetMarkdownReport`
  App-facing result of preset-backed CSV execution plus Markdown export.
- `BKAppScenarioBundleReport`
  App-facing result of deterministic scenario execution plus portable bundle export.
- `BKPreflightedRunSummary`
  Structured output for CSV preflight plus preset execution workflows.
- `BKV2ValidatedRunReport`
  Bundled preflight, request validation, and execution result for inline v2 CSV flows.
- `BKV3ValidatedRunReport`
  Bundled preflight, request validation, and execution result for inline v3 CSV flows.
- `BKStrategyRecipe`
  Stable manager-owned strategy recipe enum for additive helper workflows.
- `BKIndicatorBundleResult`
  Enriched candle series plus applied indicator keys.
- `BKManagerReportSnapshot`
  Compact packaging of report and advanced-performance highlights.
- `BKStrategyRecipeReport`
  Raw result plus summary/report packaging for manager-owned recipe flows.
- `BKToolPreflightReport`
  Validation readiness plus row count/date range and diagnostics events.
- `BKDiagnosticsSnapshotReport`
  Event counts, time range, stage counts, and last failure-like event.
- `BKToolExportBundle`
  Preflight-oriented export payloads.
- `BKRunExportBundle`
  Summary-oriented export payloads for run/scenario workflows.
- `BKRunMetricDiff`
  Headline metric deltas between baseline and candidate run summaries.
- `BKRunSummaryDiff`
  Structured summary-level diff including metadata and metric changes.
- `BKRunComparisonReport`
  Tolerance-aware comparison report for summary-oriented regressions.
- `BKComparisonAssertionError`
  Error payload thrown by `BKComparisonTool.assertEquivalent(...)` on material summary differences.
- `BKScenarioReadinessReport`
  Validation-style readiness output for deterministic scenario config checks.
- `BKScenarioSmokeCaseReport`
  One case inside a deterministic smoke suite.
- `BKScenarioSmokeSuiteReport`
  Aggregate output for deterministic scenario smoke matrix runs.

## 8) Manager Helper Bundles

`BacktestingKitManager` now includes additive mid-level helpers for common composition paths.

- `applyTrendIndicatorBundle(candles:smaPeriods:emaPeriods:keyNamespace:)`
- `applyMomentumIndicatorBundle(candles:rsiPeriod:stochasticKPeriod:stochasticDPeriod:keyNamespace:)`
- `applyVolatilityIndicatorBundle(candles:atrPeriod:bollingerPeriod:bollingerStdDev:keyNamespace:)`
- `applyDefaultScreeningBundle(candles:keyNamespace:)`
  Applies the package's default trend + momentum + volatility screening set in one pass.
- `buildHeadlineMetrics(from:)`
- `buildSummary(symbol:candles:result:)`
- `buildReportSnapshot(from:candles:)`
- `buildReportSnapshot(from:)`
- `buildAdvancedPerformanceMetrics(from:candles:minimumAcceptableReturn:)`
- `runSMACrossoverSummary(symbol:candles:fast:slow:)`
- `runEMAFastSlowSummary(symbol:candles:fastPeriod:slowPeriod:)`
- `parseAndRunRecipe(_:,csv:dateFormat:reverse:columnMapping:)`
  Parses inline CSV, converts to candles, and runs a stable built-in recipe.
- `runStrategyRecipe(_:,candles:)`
- `runStrategyRecipeSummary(_:,symbol:candles:)`
- `runRecipeReport(_:,symbol:candles:minimumAcceptableReturn:)`
  Returns the raw result, compact summary, report snapshot, and advanced metrics in one bundle.

## 9) Tool Workflow Helpers

Validation, diagnostics, export, and synthetic-scenario helpers:

- `BKValidationTool.preflightCSV(_:symbol:columnMapping:)`
  Richer CSV readiness workflow with row count and parsed date range.
- `BKDiagnosticsCollector.summarizedSnapshot()`
  Packages retained diagnostics into a compact export/report shape.
- `BKExportTool.exportPreflight(_:trades:prettyPrinted:)`
  Encodes preflight, diagnostics, and optional trades into a bundle.
- `BKExportTool.exportRunBundle(summary:trades:diagnostics:scenario:prettyPrinted:)`
  Encodes run/scenario workflows into a portable summary bundle.
- `BKExportTool.exportMarkdownSummary(_:,title:)`
  Renders a compact run summary into human-readable Markdown.
- `BKComparisonTool.diffSummaries(baseline:candidate:)`
  Produces a structured field-by-field summary diff.
- `BKComparisonTool.compareRuns(baseline:candidate:tolerance:)`
  Flags whether summary changes exceed a caller-provided tolerance.
- `BKComparisonTool.assertEquivalent(baseline:candidate:tolerance:)`
  Throws `BKComparisonAssertionError` when material differences remain after tolerance is applied.
- `BKScenarioTool.validate(config:)`
  Checks deterministic scenario config sanity before execution.
- `BKScenarioTool.summarize(config:)`
  Runs a deterministic scenario and returns a `BKRunSummary`.
- `BKScenarioTool.runExportBundle(config:diagnostics:prettyPrinted:)`
  Runs a deterministic scenario and exports summary-oriented artifacts.
- `BKScenarioTool.defaultSmokeConfigs()`
  Returns the package's deterministic smoke matrix defaults.
- `BKScenarioTool.smokeSuite(configs:)`
  Runs a deterministic smoke suite and returns structured pass/fail results per case.

## 10) App Facade

`BKAppFacade` is the app-facing helper namespace for beginner and integration workflows.

- `buildCSVImportScreenState(symbol:csv:maxRows:)`
  Builds one import-review payload with inspection, inference, preview, validation, normalization, grouped issues, and a readiness flag for app import screens.
- `runConfirmedCSVImport(from:csv:preset:confirmedSettings:log:)`
  Executes a reviewed CSV import using the screen-state settings or explicit user-confirmed overrides.
- `diagnoseCSVImport(symbol:csv:maxFailureRows:)`
  Builds a developer-facing postmortem report with stage decisions, inferred/effective settings, and bounded row-level failure examples.
- `inspectCSV(symbol:csv:columnMapping:)`
  Returns a compact structural readiness report over imported CSV.
- `detectCSVImportSettings(symbol:csv:)`
  Safely infers CSV import settings and reports both inferred and effective settings for app-side auto-apply flows.
- `previewCSV(symbol:csv:dateFormat:reverse:columnMapping:maxRows:)`
  Builds a bounded preview payload for app import screens.
- `previewCSVAuto(symbol:csv:maxRows:)`
  Applies the safe inference layer, then returns a bounded preview plus the inference report.
- `validateCSVImport(symbol:csv:dateFormat:reverse:columnMapping:)`
  Combines structural preflight and parse validation into one app-facing report.
- `validateCSVImportAuto(symbol:csv:)`
  Uses safe inferred settings before returning the same app-facing validation payload.
- `normalizeCSVImport(symbol:csv:dateFormat:reverse:columnMapping:)`
  Returns validated bars/candles plus date-range and row-count metadata.
- `normalizeCSVImportAuto(symbol:csv:)`
  Uses safe inferred settings before returning normalized bars/candles plus the inference report.
- `runCSVImport(symbol:csv:preset:dateFormat:reverse:columnMapping:log:)`
  Runs the full app-side CSV import path through a preset-backed execution helper.
- `runCSVImportAuto(symbol:csv:preset:log:)`
  Uses safe inferred settings, normalizes descending input when needed, and runs the same preset-backed app import path.
- `runCSVImportAndExportMarkdown(...)`
  Runs CSV import plus Markdown summary export in one call.
- `runCSVImportAutoAndExportMarkdown(...)`
  Runs the auto-inference import path and exports a Markdown summary when successful.
- `runPreset(dataset:preset:log:)`
- `runPresetCSV(symbol:csv:preset:dateFormat:reverse:columnMapping:log:)`
- `preflightAndRunCSV(symbol:csv:preset:dateFormat:reverse:columnMapping:log:)`
- `runScenario(config:)`
- `runV2ValidatedCSV(...)`
- `runV3ValidatedCSV(...)`
- `exportMarkdownSummary(_:,title:)`
- `exportRunBundle(summary:trades:diagnostics:scenario:prettyPrinted:)`
- `compareRuns(baseline:candidate:tolerance:)`
- `assertEquivalent(baseline:candidate:tolerance:)`
- `runPresetCSVAndExportMarkdown(...)`
- `runScenarioAndExportBundle(config:diagnostics:prettyPrinted:)`

CSV import models:

- `BKAppCSVInspectionReport`
- `BKAppCSVInferenceIssue`
- `BKAppCSVInferredSettings`
- `BKAppCSVEffectiveSettings`
- `BKAppCSVInferenceReport`
- `BKAppCSVPreviewRow`
- `BKAppCSVPreviewReport`
- `BKAppCSVAutoPreviewReport`
- `BKAppCSVValidationReport`
- `BKAppCSVAutoValidationReport`
- `BKAppCSVNormalizedReport`
- `BKAppCSVAutoNormalizedReport`
- `BKAppCSVImportScreenStatus`
- `BKAppCSVImportIssueSource`
- `BKAppCSVImportIssueItem`
- `BKAppCSVImportIssueSection`
- `BKAppCSVImportScreenState`
- `BKAppCSVImportRunReport`
- `BKAppCSVAutoRunReport`
- `BKAppCSVImportMarkdownReport`
- `BKAppCSVAutoMarkdownReport`
- `BKAppCSVImportStageDecision`
- `BKAppCSVImportFailureStage`
- `BKAppCSVRowFailureExample`
- `BKAppCSVImportDiagnosticsReport`

- `BKBacktestOptions`
- `BKPosition`
- `BKEnterPositionOptions`
- `BKRuleParams`
- `BKOpenPositionRuleArgs`
- `BKStrategy`
- `backtest(strategy:inputSeries:options:)`
- `analyze(startingCapital:trades:)`

Rule closure aliases:

- `EnterPositionFn`
- `ExitPositionFn`
- `BKEntryRuleFn`
- `BKExitRuleFn`
- `BKStopLossFn`
- `BKProfitTargetFn`

Lifecycle enums:

- `TradeDirection`
- `PositionStatus`

## Post-processing

- `v3postAnalysis(...)`
- `postAnalysis(...)`

## 7) High-Level Manager API

## `BacktestingKitManager`

Facade implementing:

- `BKIndicatorComputing`
- `BKStrategyBacktesting`
- `BKStrategyEvaluationReporting`
- combined as `BKBacktestingEngine`

Use this when you want direct indicator/backtest workflows on `Candlestick` arrays.

## Engine POP protocols (`Engine/BKEngineProtocols.swift`)

- `BKIndicatorComputing`
- `BKStrategyBacktesting`
- `BKStrategyEvaluationReporting`
- `BKBacktestingEngine` (composed protocol)
- `BKAnyBacktestingEngine` (existential typealias)

## Candle-level models

- `Candlestick`
- `Trade`
- `BacktestResult`
- `BacktestMetricsReport`
- `BKAdvancedPerformanceMetrics`
- `BKExecutionAdjustedTrade`

## 8) Indicator and Strategy Surfaces

## Built-in indicator pipelines

- v2: `v2setTechnicalIndicators(...)`
- v3: `v3setTechnicalIndicators(...)`

## Rule function selection

- v2: `v2getCheckingFunction(...)`
- v3: `v3getCheckingFunction(...)`
- v3 typealias: `BKCheckFn`

## Strategy factory

- `getStrategy(...)`
  Builds runtime strategy closures from model-level policy/rules.

## Preset policy builders (`Engine/BKPresets.swift`)

- Bollinger, SMA/EMA, MACD variants, crossover variants, mean reversion, stochastic variants.
- `v3GetPresetRules(preset:)`
- `getSimulatePolicyConfig(preset:)`

## Preset catalog (`Engine/BKPresetCatalog.swift`)

- `BKPresetCatalog`
  Unified discoverable enum for supported preset families.

## Execution/risk/portfolio preset profiles (`Engine/BKPresetStrategies.swift`)

- `BKExecutionPresetProfile`
- `BKPositionSizingPresetProfile`
- `BKRiskControlPresetProfile`
- `BKEvaluationPresetProfile`
- `BKPortfolioPresets`

## 9) Execution and Position Sizing Models

## Execution model protocols

- `BKSlippageModel`
- `BKCommissionModel`

Concrete models:

- `BKNoSlippageModel`
- `BKFixedBpsSlippageModel`
- `BKNoCommissionModel`
- `BKFixedPlusPercentCommissionModel`

## Position sizing protocol + models

- `BKPositionSizingModel`
- `BKVolatilityTargetingSizer`
- `BKFixedFractionalSizer`
- `BKKellyCappedSizer`

## 10) Optimization and Research APIs

## Optimization (`Analysis/BKOptimization.swift`)

- `computeEquityCurve(...)`
- `computeDrawdown(...)`
- `optimize(...)`
- `walkForwardOptimize(...)`
- `monteCarlo(...)`

Supporting types:

- `ObjectiveFn`
- `OptimizeSearchDirection`
- `ParameterDef`
- `OptimizationType`
- `OptimizationOptions`
- `OptimizationIterationResult`
- `OptimizationResult`
- `WalkForwardOptimizationResult`
- `MonteCarloOptions`

## 11) Model Surface (Parity and Interop)

## Core model families (`Core/BKTypes.swift`)

Enums and structs for simulation policies, indicators, status, user/device/instrument/config metadata, optimization records, rules, and typed analysis/trade payloads:

- `BKEntitlement`, `TierSet`, `BKMinMax`, `CompareOption`
- `SimulationPolicy`, `TechnicalIndicators`, `SimulationStatus`
- `BKAnalysis`, `BKTimestampedValue`, `BKTrade`
- `SimulationRule`, `SimulationPolicyConfig`
- `OptimizePolicyConfig`, `OptimizeRule`, `OptimizeRulesContainer`, `OptimizeResult`
- `User`, `Device`, `Instrument`, `Config`
- `TriggerType`, `DynamodbTrigger`
- `SimulationTimeframe`
- `BKAnalysisTypeCheck(...)`

## v2 model namespace

- `BKV2` (nested model surface including v2 policy/rule/analysis/trade structures)

## v3 model namespace

- `BKV3_AnalysisProfile`
- `BKV3_Config`
- `BKV3_InstrumentInfo`
- `BKV3_InstrumentDetail`
- `BKV3_OptimizePolicyConfig`
- `BKV3_OptimizeResult`
- `BKV3_OptimizeRule`
- `BKV3_RiskProfile`
- `BKV3_SimulationRule`
- `RuleType`
- `BKV3_TradeEntry`
- `BKV3_UserDevice`
- `DeviceType`
- `BKV3_UserProfile`
- `BKV3_UserSubscription`
- `BKV3_UserDeletion`

## External-series compatibility models (`Models/External/BKSeriesModels.swift`)

Public dataframe/series types and utilities used for parity-compatible indicator math and tabular operations:

- `DFSeriesWindow`
- `DFSeries`
- `DFBollingerRow`
- `DFMacdRow`
- `DFDataFrame`
- `DFIndex`
- `DFPair`
- `DFWhichIndex`
- `DFDataFrameAny`
- `DFJoinType`
- `DFPivot`
- `DFCSV`

## 12) Conversion and Utility APIs

## Model conversion (`Support/BKModelConversion.swift`)

- `convertSimulationRule(...)`
- `convertAnalysis(...)`
- `convertTradesWithRisks(...)`
- `convertTrade(...)`
- `convertRisk(...)`
- `convertRisks(...)`

## Codable helpers

- `BKCoders`

## 13) Error Mapping API

## `BKErrorMapper`

Centralized mapper that converts lower-level errors into UI-facing `BKEngineFailure` payloads.

Use this when integrating custom providers/stores so all errors preserve consistent shape for UI handling.

## 14) UI Presentation Protocols

These protocols standardize how success/error payloads are rendered by UI layers.

- `BKUserPresentablePayload`
  - `uiTitle`
  - `uiSummary`
  - `uiDescription`
  - `uiMetadata`
- `BKUserPresentableError` (extends `BKUserPresentablePayload` + `Error`)
  - `uiErrorCode`
  - `uiRetryable`
- `BKResultPresentation`
  - normalized envelope for UI display
- `Result.uiPresentation` extension
  - available when `Success: BKUserPresentablePayload` and `Failure: BKUserPresentableError`

Current built-in conformances include:

- Errors: `BKEngineFailure`, `BKCSVParsingError`, `AlphaVantageClientError`, `BKQuickDemoError`, `BKSimulationDriverError`
- Success payloads: `BKSimulationInstrumentReport`, `BKSimulationBatchReport`, `BKSimulationBatchDetailedReport`, `BKQuickDemoSummary`, `BKV2.SimulateConfigOutput`, `PositionStatus`

Result adapters for gap-free UI presentation without changing return models:

- `BKAnyPresentationError` (adapts erased `Error` into UI-presentable error data)
- Specialized `Result.uiPresentation` for:
  - `Result<(BKV2.SimulateConfigOutput, PositionStatus), BKEngineFailure>`
  - `Result<Success, Error>` where `Success: BKUserPresentablePayload`

## 15) Compatibility Typealiases

- `BKEngineV3Request`
- `BKEngineV2Request`
- `BKDemoDataset`

## 16) Additive Utility Tools

These APIs are additive helpers and do not change v2/v3 engine output model shape.

## Validation

- `BKValidationTool`
  - `validateCSV(_:columnMapping:)`
  - `validateV2Request(_:)`
  - `validateV3Request(_:)`
- `BKValidationSeverity`
- `BKValidationIssue`
- `BKValidationReport`

## Diagnostics

- `BKDiagnosticEventKind`
- `BKDiagnosticEvent`
- `BKDiagnosticsCollector`

## Benchmarking

- `BKBenchmarkSample`
- `BKBenchmarkResult`
- `BKBenchmarkTool`
  - `run(...)`
  - `runAsync(...)`

## Parity

- `BKParityMismatch`
- `BKParityReport`
- `BKParityTool`
  - `compareMetrics(expected:actual:tolerance:)`
  - `compareAnalysis(expected:actual:tolerance:)`

## Scenario

- `BKScenarioStrategy`
- `BKScenarioConfig`
- `BKScenarioResult`
- `BKScenarioTool`
  - `generateCandles(config:)`
  - `run(config:)`

## Comparison

- `BKRunMetricDiff`
- `BKRunSummaryDiff`
- `BKRunComparisonReport`
- `BKComparisonTool`
  - `diffSummaries(baseline:candidate:)`
  - `compareRuns(baseline:candidate:tolerance:)`

## Export

- `BKExportError`
- `BKExportTool`
  - `toJSON(_:prettyPrinted:)`
  - `tradesToCSV(_:)`
