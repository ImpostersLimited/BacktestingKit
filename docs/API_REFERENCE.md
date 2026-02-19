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

## Export

- `BKExportError`
- `BKExportTool`
  - `toJSON(_:prettyPrinted:)`
  - `tradesToCSV(_:)`
