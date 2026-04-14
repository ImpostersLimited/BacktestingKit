# Package Usage Guide

This guide explains how to use BacktestingKit by workflow. Use it when you want a practical answer to "which API should I call?".

For the linear beginner path, start at [ONBOARDING.md](ONBOARDING.md). For the full documentation map, start at [INDEX.md](INDEX.md). For the public symbol inventory, see [API_REFERENCE.md](API_REFERENCE.md).

## Choose a workflow

| Goal | Start here | Primary types |
| --- | --- | --- |
| Start from one app-facing helper namespace | `BKAppFacade` | `BKAppPresetMarkdownReport`, `BKAppScenarioBundleReport`, `BKAppCSVInspectionReport`, `BKAppCSVImportScreenState`, `BKAppCSVImportRunReport` |
| Prove the package works offline in seconds | `BKEngine.runDemo`, `BKQuickDemo` | `BKQuickDemoDataset`, `BKQuickDemoSummary` |
| Run from inline CSV without defining providers | `BKEngine.runDemoCSV`, `runPresetCSV`, `preflightAndRunCSV`, `runV2CSV`, `runV2ValidatedCSV`, `runV3CSV`, `runV3ValidatedCSV` | `BKInlineCsvProvider`, `BKCSVColumnMapping`, `BKPreflightedRunSummary` |
| Run canonical app-facing engine requests | `BKEngine.runV2`, `BKEngine.runV3` | `BKEngine.V2Request`, `BKEngine.V3Request` |
| Compose indicators and strategy recipes over candles | `BacktestingKitManager` | `Candlestick`, `BKStrategyRecipe`, `BKIndicatorBundleResult` |
| Validate/export/compare/benchmark runs | helper tools | `BKValidationTool`, `BKExportTool`, `BKComparisonTool`, `BKBenchmarkTool`, `BKParityTool` |
| Orchestrate low-level or batch simulation | simulation drivers | `BKSimulationDriver`, `BKV2SimulationDriver`, `BKSimulationBatchOptions` |
| Extend data access or persistence | provider/store protocols | `BKRawCsvProvider`, `BKV3DataStore`, `BKBarParsing` |

If you are completely new to the package, do not start by choosing from this table. Start with [ONBOARDING.md](ONBOARDING.md), then return here once you have had a first successful run.

## 0. Start from the app-facing facade

Use `BKAppFacade` when you want one namespace for common app workflows without wiring request models immediately.

```swift
let report = BKAppFacade.runPresetCSVAndExportMarkdown(
    symbol: "AAPL",
    csv: csv,
    preset: .smaCrossover
)
```

`BKAppFacade` delegates to the current engine and tool helpers. It is the shortest app-integration path, not a separate runtime.

### App-side CSV import flow

Use the CSV import helpers when your app needs to inspect, preview, validate, normalize, and then execute imported CSV without composing the lower-level parsing and validation surfaces manually.

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

This is the recommended path for onboarding UIs, CSV import sheets, and simple app integration flows that start from user-supplied CSV. `buildCSVImportScreenState(...)` is the best starting point when the app needs one ready-to-render review payload before execution.
Use `runConfirmedCSVImport(...)` once the app has accepted the review state or applied explicit user overrides.
Use `diagnoseCSVImport(...)` only when you need a developer-facing postmortem report for debugging or import triage; it is not the screen-state helper.

When the app does not know the settings yet, use the explicit auto-inference path. The auto helpers infer only safe defaults, report the inferred and effective settings, and normalize descending input before delegating to the existing manual helpers.

```swift
let inference = BKAppFacade.detectCSVImportSettings(symbol: "AAPL", csv: csv)
let preview = BKAppFacade.previewCSVAuto(symbol: "AAPL", csv: csv, maxRows: 5)
let validation = BKAppFacade.validateCSVImportAuto(symbol: "AAPL", csv: csv)
let normalized = BKAppFacade.normalizeCSVImportAuto(symbol: "AAPL", csv: csv)
let run = BKAppFacade.runCSVImportAuto(symbol: "AAPL", csv: csv, preset: .smaCrossover)
```

## 1. Smoke-test the package

Use this path when you want an offline sanity check with no network dependency.

```swift
import BacktestingKit

let result = BKEngine.runDemo(dataset: .aapl) { line in
    print(line)
}

switch result {
case .success(let summary):
    print(summary.symbol)
    print(summary.barCount)
    print(summary.metrics.totalReturn)
case .failure(let error):
    print(error.localizedDescription)
}
```

Related APIs:

- `BKEngine.runDemo(dataset:csv:log:)`
- `BKQuickDemo.runBundledSMACrossoverDemo(...)`
- `BKQuickDemo.runBundledPresetDemo(...)`
- `BKQuickDemo.runBundledSmokeMatrix(...)`

See also: [GETTING_STARTED.md](GETTING_STARTED.md), [HELPER_WORKFLOWS.md](HELPER_WORKFLOWS.md)

## 2. Run helper workflows from inline CSV

Use this path when your app or tests already have CSV text and you want the shortest route into the package.

### Demo helper

```swift
let csv = """
timestamp,open,high,low,close,volume
2024-01-01,100,101,99,100.5,1000000
2024-01-02,100.5,102,100,101.5,1100000
"""

let result = BKEngine.runDemoCSV(symbol: "AAPL", csv: csv, fast: 5, slow: 20)
```

### Preset + preflight helpers

```swift
let presetSummary = BKEngine.runPresetCSV(
    symbol: "AAPL",
    csv: csv,
    preset: .emaMeanReversion
)

let preflighted = BKEngine.preflightAndRunCSV(
    symbol: "AAPL",
    csv: csv,
    preset: .smaCrossover
)
```

### v2 helper

```swift
let result = await BKEngine.runV2CSV(
    instrumentID: "AAPL",
    config: config,
    csv: csv
)
```

### v3 helper

```swift
let result = await BKEngine.runV3CSV(
    instrument: instrument,
    dataStore: dataStore,
    csv: csv
)
```

### Validated engine helpers

```swift
let validatedV2 = await BKEngine.runV2ValidatedCSV(
    instrumentID: "AAPL",
    config: config,
    csv: csv
)

let validatedV3 = await BKEngine.runV3ValidatedCSV(
    instrument: instrument,
    dataStore: dataStore,
    csv: csv
)
```

If your CSV uses nonstandard headers, pass a `BKCSVColumnMapping`.

## 3. Use the canonical engine entrypoints

Use `BKEngine` when you want the stable app-facing execution surface.

### v3 one-shot execution

```swift
let request = BKEngine.V3Request(
    instrument: instrument,
    p1: 5,
    p2: 20,
    executionOptions: .init(parserMode: .streamingStrict),
    dataStore: dataStore,
    csvProvider: provider,
    log: { print($0) }
)

let result = await BKEngine.runV3(request)
```

### v2 one-shot execution

```swift
let request = BKEngine.V2Request(
    instrumentID: "AAPL",
    config: config,
    p1: 5,
    p2: 20,
    csvProvider: provider,
    log: { print($0) }
)

let result = await BKEngine.runV2(request)
```

The lower-level compatibility aliases on `BKEngineOneLiner` remain available when you want the older naming surface.

See also: [ENGINE_GUIDE.md](ENGINE_GUIDE.md)

## 4. Work with data, parsing, and providers

Use these APIs when you need control over ingestion or want to integrate your own data backend.

### Parse CSV directly

```swift
let barsResult = csvToBars(
    csv,
    dateFormat: "yyyy-MM-dd",
    reverse: false,
    strict: true,
    columnMapping: nil
)
```

### Define your own provider

```swift
struct MyProvider: BKRawCsvProvider {
    let csv: String

    func getRawCsv(ticker: String, p1: Double, p2: Double) async -> Result<String, Error> {
        .success(csv)
    }
}
```

### Use a closure-backed provider

```swift
let provider = BKCustomCsvProvider { ticker, p1, p2 in
    await gateway.fetchCsv(symbol: ticker, p1: p1, p2: p2)
}
```

### Useful ingestion types

- `BKCSVColumnMapping`
- `BKCSVParsingError`
- `BKCSVBarParser`
- `BKInlineCsvProvider`
- `BKCachedCsvProvider`
- `AlphaVantageClient`

See also: [DATA_INGESTION.md](DATA_INGESTION.md)

## 5. Use manager workflows for candles, indicators, and recipes

Use `BacktestingKitManager` when you are already working with `Candlestick` arrays and want indicator composition or strategy execution without the v2/v3 request layers.

### Strategy recipe helpers

```swift
let manager = BacktestingKitManager()

let summary = manager.runStrategyRecipeSummary(
    .rsi2MeanReversion(trendPeriod: 200, entryThreshold: 10, exitThreshold: 60),
    symbol: "AAPL",
    candles: candles
)

let result = manager.parseAndRunRecipe(
    .smaCrossover(fast: 5, slow: 20),
    csv: csv
)

let report = manager.runRecipeReport(
    .emaFastSlow(),
    symbol: "AAPL",
    candles: candles
)
```

### Indicator bundle helpers

```swift
let trend = manager.applyTrendIndicatorBundle(
    candles: candles,
    smaPeriods: [5, 20],
    emaPeriods: [12, 26],
    keyNamespace: "screen"
)

let screening = manager.applyDefaultScreeningBundle(candles: candles)
```

### Report helpers

```swift
let result = manager.runStrategyRecipe(.smaCrossover(fast: 5, slow: 20), candles: candles)
let snapshot = manager.buildReportSnapshot(from: result, candles: candles)
let metrics = manager.buildAdvancedPerformanceMetrics(from: result, candles: candles)
```

Related types:

- `BKStrategyRecipe`
- `BKIndicatorBundleResult`
- `BKManagerReportSnapshot`
- `BKRunSummary`
- `BKRunHeadlineMetrics`

See also: [INDICATORS_STRATEGIES_METRICS.md](INDICATORS_STRATEGIES_METRICS.md), [HELPER_WORKFLOWS.md](HELPER_WORKFLOWS.md)

## 6. Use tooling helpers around validation, export, scenarios, and comparison

Use these helpers for onboarding UIs, smoke tests, deterministic regression checks, and CI support.

### Validation

```swift
let report = BKValidationTool.preflightCSV(csv, symbol: "AAPL")
if !report.isReady {
    print(report.validation.issues)
}
```

### Diagnostics

```swift
let collector = BKDiagnosticsCollector()
await collector.emit(kind: .simulationStarted, stage: "simulation", message: "Running")
let diagnostics = await collector.summarizedSnapshot()
```

### Scenario generation

```swift
let summary = BKEngine.runScenario(
    config: BKScenarioConfig(symbol: "SCENARIO", barCount: 64, seed: 42)
)
```

### Export and comparison

```swift
let export = BKExportTool.exportRunBundle(summary: summary)
let markdown = BKExportTool.exportMarkdownSummary(summary)

let comparison = BKComparisonTool.compareRuns(
    baseline: baselineSummary,
    candidate: candidateSummary,
    tolerance: 0.001
)

let smoke = BKScenarioTool.smokeSuite()
```

### Benchmark and parity

```swift
let bench = BKBenchmarkTool.run(name: "parse", iterations: 20) {
    _ = csvToBarsStreaming(csv, reverse: false, strict: true)
}
```

See also: [TOOLS.md](TOOLS.md), [ERROR_HANDLING_AND_DIAGNOSTICS.md](ERROR_HANDLING_AND_DIAGNOSTICS.md), [PARITY_TESTING.md](PARITY_TESTING.md)

## 7. Use low-level simulation drivers and batch orchestration

Use this path when you need more control than `BKEngine` provides.

### v3 driver

```swift
let driver = BKSimulationDriver(dataStore: dataStore, csvProvider: provider)

let result = await driver.simulateInstrumentDetailed(
    instrument,
    p1: 5,
    p2: 20,
    dateFormat: "yyyy-MM-dd",
    executionOptions: .init(parserMode: .streamingStrict)
)
```

### Batch simulation

Use:

- `simulateInstrumentsWithReport(...)`
- `simulateInstrumentsWithDetailedReport(...)`
- `startSimulationBatch(...)`

Batch execution is the right fit when you need progress reporting, per-instrument failure collection, or bounded concurrency.

See also: [ENGINE_GUIDE.md](ENGINE_GUIDE.md), [ARCHITECTURE_DEEP_DIVE.md](ARCHITECTURE_DEEP_DIVE.md)

## 8. Use analysis, metrics, and optimization helpers

Use these APIs after a backtest when you want richer performance analysis or search workflows.

Main surfaces:

- `BacktestResult`
- `BacktestMetricsReport`
- `BKAdvancedPerformanceMetrics`
- `buildMetricsReport(...)`
- `advancedPerformanceMetrics(...)`
- optimization models and search helpers under `BacktestingKit/Analysis`

See also: [INDICATORS_STRATEGIES_METRICS.md](INDICATORS_STRATEGIES_METRICS.md)

## 9. Present results safely in apps and agents

BacktestingKit keeps its app-facing surfaces `Result`-based and provides presentation-safe models:

- `BKEngineFailure`
- `BKResultPresentation`
- `BKUserPresentablePayload`
- `BKUserPresentableError`
- helper summary models like `BKRunSummary`

Use these when you need stable UI or automation-friendly output instead of raw thrown errors.

See also: [ERROR_HANDLING_AND_DIAGNOSTICS.md](ERROR_HANDLING_AND_DIAGNOSTICS.md), [AGENTIC_USAGE.md](AGENTIC_USAGE.md)

## 10. Extend the package

Extension entrypoints include:

- custom `BKRawCsvProvider` implementations
- custom `BKV3DataStore` implementations
- custom simulation driver factories via `BKEngine.makeV2Driver` / `BKEngine.makeV3Driver`
- additional indicators, strategies, metrics, and tools

See also: [EXTENDING_BACKTESTINGKIT.md](EXTENDING_BACKTESTINGKIT.md)
