# Helper Workflows

This document collects the additive helper APIs introduced for app integration, demo/smoke workflows, and operational tooling.

## App Facade

Use `BKAppFacade` when you want one app-facing namespace for helper execution, export, comparison, and app-side CSV workflows.

```swift
let report = BKAppFacade.runPresetCSVAndExportMarkdown(
    symbol: "AAPL",
    csv: csv,
    preset: .smaCrossover
)
```

Available helpers:

- CSV import flow:
  - `BKAppFacade.buildCSVImportScreenState(symbol:csv:maxRows:)`
    - app import-review UI state only
  - `BKAppFacade.diagnoseCSVImport(symbol:csv:maxFailureRows:)`
    - developer-facing postmortem diagnostics only
  - `BKAppFacade.inspectCSV(symbol:csv:columnMapping:)`
  - `BKAppFacade.detectCSVImportSettings(symbol:csv:)`
  - `BKAppFacade.previewCSV(symbol:csv:dateFormat:reverse:columnMapping:maxRows:)`
  - `BKAppFacade.previewCSVAuto(symbol:csv:maxRows:)`
  - `BKAppFacade.validateCSVImport(symbol:csv:dateFormat:reverse:columnMapping:)`
  - `BKAppFacade.validateCSVImportAuto(symbol:csv:)`
  - `BKAppFacade.normalizeCSVImport(symbol:csv:dateFormat:reverse:columnMapping:)`
  - `BKAppFacade.normalizeCSVImportAuto(symbol:csv:)`
  - `BKAppFacade.runCSVImport(symbol:csv:preset:dateFormat:reverse:columnMapping:log:)`
  - `BKAppFacade.runCSVImportAuto(symbol:csv:preset:log:)`
  - `BKAppFacade.runCSVImportAndExportMarkdown(...)`
  - `BKAppFacade.runCSVImportAutoAndExportMarkdown(...)`
- `BKAppFacade.runPreset(dataset:preset:log:)`
- `BKAppFacade.runPresetCSV(symbol:csv:preset:dateFormat:reverse:columnMapping:log:)`
- `BKAppFacade.preflightAndRunCSV(symbol:csv:preset:dateFormat:reverse:columnMapping:log:)`
- `BKAppFacade.runScenario(config:)`
- `BKAppFacade.runV2ValidatedCSV(...)`
- `BKAppFacade.runV3ValidatedCSV(...)`
- `BKAppFacade.exportMarkdownSummary(_:,title:)`
- `BKAppFacade.exportRunBundle(summary:trades:diagnostics:scenario:prettyPrinted:)`
- `BKAppFacade.compareRuns(baseline:candidate:tolerance:)`
- `BKAppFacade.assertEquivalent(baseline:candidate:tolerance:)`
- `BKAppFacade.runConfirmedCSVImport(from:csv:preset:confirmedSettings:log:)`
- `BKAppFacade.runPresetCSVAndExportMarkdown(...)`
- `BKAppFacade.runScenarioAndExportBundle(config:diagnostics:prettyPrinted:)`

Example CSV import workflow:

```swift
let screenState = BKAppFacade.buildCSVImportScreenState(
    symbol: "AAPL",
    csv: csv,
    maxRows: 5
)

if screenState.isReadyToContinue {
    let run = BKAppFacade.runConfirmedCSVImport(
        from: screenState,
        csv: csv,
        preset: .smaCrossover
    )
}
```

`buildCSVImportScreenState(...)` is the app import-review UI state helper. `runConfirmedCSVImport(...)` is the review-to-execution bridge when the app is ready to continue or has applied explicit user overrides. `diagnoseCSVImport(...)` is separate and is meant for developer-facing postmortem analysis of the import pipeline.

Example auto-inference import workflow:

```swift
let inference = BKAppFacade.detectCSVImportSettings(symbol: "AAPL", csv: csv)
let preview = BKAppFacade.previewCSVAuto(symbol: "AAPL", csv: csv, maxRows: 5)
let validation = BKAppFacade.validateCSVImportAuto(symbol: "AAPL", csv: csv)
let normalized = BKAppFacade.normalizeCSVImportAuto(symbol: "AAPL", csv: csv)
let run = BKAppFacade.runCSVImportAuto(symbol: "AAPL", csv: csv, preset: .smaCrossover)
```

## Engine Workflows

Use `BKEngine` when you want the shortest path from input data to a stable run summary.

```swift
let result = BKEngine.runDemoCSV(symbol: "AAPL", csv: csv)
```

Available helpers:

- `BKEngine.runPreset(dataset:preset:log:)`
- `BKEngine.runPresetCSV(symbol:csv:preset:dateFormat:reverse:columnMapping:log:)`
- `BKEngine.preflightAndRunCSV(symbol:csv:preset:dateFormat:reverse:columnMapping:log:)`
- `BKEngine.runScenario(config:)`
- `BKEngine.summarize(symbol:bars:result:)`
- `BKEngine.summarize(symbol:candles:result:)`
- `BKEngine.runDemoCSV(symbol:csv:fast:slow:log:)`
- `BKEngine.runV2CSV(...)`
- `BKEngine.runV2ValidatedCSV(...)`
- `BKEngine.runV3CSV(...)`
- `BKEngine.runV3ValidatedCSV(...)`
- `BKEngineOneLiner.runBKV2CSV(...)`
- `BKEngineOneLiner.runBKV3CSV(...)`

## Bundled Demo Workflows

Use `BKQuickDemo` for offline onboarding, smoke tests, and deterministic examples.

```swift
let summary = BKQuickDemo.runBundledPresetDemo(
    dataset: .aapl,
    preset: .smaCrossover
)
```

```swift
let matrix = BKQuickDemo.runBundledSmokeMatrix(
    datasets: [.aapl, .msft, .nvda],
    preset: .emaMeanReversion
)
```

Supporting helpers:

- `loadBundledCSV(dataset:)`
- `parseBars(csv:dateFormat:reverse:columnMapping:)`
- `makeCandles(from:)`
- `summarize(symbol:bars:result:)`

## Manager Workflows

Use `BacktestingKitManager` helpers when you want reusable indicator composition or a summary-oriented wrapper without dropping to raw report construction.

```swift
let manager = BacktestingKitManager()
let trend = manager.applyTrendIndicatorBundle(
    candles: candles,
    smaPeriods: [5, 20],
    emaPeriods: [12, 26],
    keyNamespace: "screen"
)

let summary = manager.runSMACrossoverSummary(
    symbol: "AAPL",
    candles: trend.candles,
    fast: 5,
    slow: 20
)

let recipeSummary = manager.runStrategyRecipeSummary(
    .rsi2MeanReversion(trendPeriod: 50),
    symbol: "AAPL",
    candles: candles
)

let recipeReport = manager.runRecipeReport(
    .emaFastSlow(fastPeriod: 12, slowPeriod: 26),
    symbol: "AAPL",
    candles: candles
)

let screening = manager.applyDefaultScreeningBundle(candles: candles)
```

Available helpers:

- trend, momentum, and volatility indicator bundles
- `parseAndRunRecipe(_:,csv:dateFormat:reverse:columnMapping:)`
- `runStrategyRecipe(_:,candles:)`
- `runStrategyRecipeSummary(_:,symbol:candles:)`
- `runRecipeReport(_:,symbol:candles:minimumAcceptableReturn:)`
- `applyDefaultScreeningBundle(candles:keyNamespace:)`
- `buildHeadlineMetrics(from:)`
- `buildSummary(symbol:candles:result:)`
- `buildReportSnapshot(...)`
- `buildAdvancedPerformanceMetrics(...)`
- `runSMACrossoverSummary(...)`
- `runEMAFastSlowSummary(...)`

## Tool Workflows

Use the tool helpers for onboarding, diagnostics, export, and deterministic scenario flows.

```swift
let preflight = BKValidationTool.preflightCSV(csv, symbol: "AAPL")
```

```swift
let collector = BKDiagnosticsCollector()
await collector.emit(kind: .simulationStarted, stage: "simulation", message: "Running")
let diagnostics = await collector.summarizedSnapshot()
```

```swift
let bundle = BKScenarioTool.runExportBundle(
    config: BKScenarioConfig(symbol: "SCENARIO", seed: 42),
    diagnostics: diagnostics
)

let comparison = BKComparisonTool.compareRuns(
    baseline: baselineSummary,
    candidate: candidateSummary,
    tolerance: 0.001
)

let smoke = BKScenarioTool.smokeSuite()
```

Available helpers:

- `BKValidationTool.preflightCSV(...)`
- `BKDiagnosticsCollector.summarizedSnapshot()`
- `BKExportTool.exportPreflight(...)`
- `BKExportTool.exportRunBundle(...)`
- `BKExportTool.exportMarkdownSummary(_:,title:)`
- `BKComparisonTool.diffSummaries(...)`
- `BKComparisonTool.compareRuns(...)`
- `BKComparisonTool.assertEquivalent(...)`
- `BKScenarioTool.validate(config:)`
- `BKScenarioTool.summarize(config:)`
- `BKScenarioTool.runExportBundle(...)`
- `BKScenarioTool.defaultSmokeConfigs()`
- `BKScenarioTool.smokeSuite(configs:)`
