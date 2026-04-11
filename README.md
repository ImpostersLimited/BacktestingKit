# BacktestingKit

BacktestingKit is a Swift framework for running strategy backtests and simulation workflows with model parity to an existing JavaScript engine (v2 and v3 paths).

Current release track: **v0.1.0**.

## Highlights

- v2 and v3 simulation engines with parity-oriented data models.
- Strategy/rule evaluation plus indicator generation.
- Built-in analysis, optimization, walk-forward, and Monte Carlo helpers.
- Strict CSV ingestion support:
  - ISO8601 date parsing.
  - Chronological input enforcement.
  - Explicit parse errors for UI handling.
  - Custom OHLCV column mapping.
- Batch simulation driver with progress and structured error reporting.
- Data source is provider-driven (`BKRawCsvProvider`), not hard-coded to a single vendor.

## Project Structure

- `BacktestingKit/Core` – foundational shared types.
- `BacktestingKit/Models` – v2/v3/external model definitions.
- `BacktestingKit/Indicators` – v2/v3 indicator setup.
- `BacktestingKit/Rules` – v2/v3 rule evaluation.
- `BacktestingKit/Simulation` – v2/v3 simulation entrypoints and drivers.
- `BacktestingKit/Data` – CSV parsing, providers, cache, AlphaVantage support.
- `BacktestingKit/Analysis` – post-analysis and optimization helpers.
- `BacktestingKit/Engine` – presets, strategy factory, high-level manager APIs.
- `BacktestingKit/Support` – coders/model conversion helpers.

See also: `BacktestingKit/ARCHITECTURE.md`

## Quick Start

Open and build:

```bash
swift build
```

Basic CSV parse:

```swift
let parseResult = csvToBars(csv, reverse: false)
if case .success(let bars) = parseResult {
    // use bars
}
```

Choose your path:

- Beginner onboarding: `docs/ONBOARDING.md`
- Beginner app facade: `BKAppFacade`
- App-side CSV import/validation:
  - Import-review path: `BKAppFacade.buildCSVImportScreenState(...)`
  - Confirmed execution handoff: `BKAppFacade.runConfirmedCSVImport(...)`
  - Developer diagnostics path: `BKAppFacade.diagnoseCSVImport(...)`
  - Manual settings path: `BKAppFacade.inspectCSV(...)`, `previewCSV(...)`, `validateCSVImport(...)`, `normalizeCSVImport(...)`, `runCSVImport(...)`
  - Auto-inference path: `BKAppFacade.detectCSVImportSettings(...)`, `previewCSVAuto(...)`, `validateCSVImportAuto(...)`, `normalizeCSVImportAuto(...)`, `runCSVImportAuto(...)`
- Surface guide: `docs/CHOOSE_YOUR_SURFACE.md`
- Offline first run: `BKEngine.runDemo(...)`
- Inline CSV helper flow: `BKEngine.runDemoCSV(...)`, `runV2CSV(...)`, `runV3CSV(...)`
- Canonical app integration: `BKEngine.runV2(...)`, `BKEngine.runV3(...)`
- Candle-first manager workflows: `BacktestingKitManager`
- Validation/export/comparison/parity tools: `BKValidationTool`, `BKExportTool`, `BKComparisonTool`, `BKParityTool`

App-facing facade example:

```swift
let report = BKAppFacade.runPresetCSVAndExportMarkdown(
    symbol: "AAPL",
    csv: csv,
    preset: .smaCrossover
)

let importScreen = BKAppFacade.buildCSVImportScreenState(
    symbol: "AAPL",
    csv: csv,
    maxRows: 5
)

let confirmedRun = BKAppFacade.runConfirmedCSVImport(
    from: importScreen,
    csv: csv,
    preset: .smaCrossover
)

let importDiagnostics = BKAppFacade.diagnoseCSVImport(
    symbol: "AAPL",
    csv: csv
)

let importPreview = BKAppFacade.previewCSV(
    symbol: "AAPL",
    csv: csv,
    maxRows: 5
)

let importAuto = BKAppFacade.runCSVImportAuto(
    symbol: "AAPL",
    csv: csv,
    preset: .smaCrossover
)
```

Canonical engine entrypoint:

```swift
// Use BKEngine as the single source of truth for engine entrypoints.
let v3Result = await BKEngine.runV3(v3Request)
let v2Result = await BKEngine.runV2(v2Request)
```

Provider injection example (no vendor lock-in):

```swift
let provider = BKCustomCsvProvider { ticker, p1, p2 in
    // Fetch CSV from your own backend/vendor and return raw CSV text.
    await MyDataGateway.shared.fetchCsv(symbol: ticker, p1: p1, p2: p2)
}
```

CSV parse with custom headers:

```swift
let mapping = BKCSVColumnMapping(
    date: "Date",
    open: "OpenPrice",
    high: "HighPrice",
    low: "LowPrice",
    close: "ClosePrice",
    volume: "TradeVolume"
)

let barsResult = csvToBars(csv, reverse: false, columnMapping: mapping)
```

Fastest CSV-backed workflow:

```swift
let csv = """
timestamp,open,high,low,close,volume
2024-01-01,100,101,99,100.5,1000000
2024-01-02,100.5,102,100,101.5,1100000
"""

let result = BKEngine.runDemoCSV(symbol: "DEMO", csv: csv)
```

Bundled preset smoke workflow:

```swift
let summary = BKQuickDemo.runBundledPresetDemo(
    dataset: .aapl,
    preset: .smaCrossover
)

let matrix = BKQuickDemo.runBundledSmokeMatrix(
    datasets: [.aapl, .msft, .nvda],
    preset: .emaMeanReversion
)
```

Manager helper workflow:

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
    candles: candles,
    fast: 5,
    slow: 20
)
```

Tool workflow example:

```swift
let preflight = BKValidationTool.preflightCSV(csv, symbol: "AAPL")
let collector = BKDiagnosticsCollector()
await collector.emit(kind: .simulationStarted, stage: "simulation", message: "Running scenario")
let diagnostics = await collector.summarizedSnapshot()
let exported = BKScenarioTool.runExportBundle(
    config: BKScenarioConfig(symbol: "SCENARIO"),
    diagnostics: diagnostics
)
```

## Trial / Parity Run

```bash
bash tools/parity/run_parity.sh
```

If your local JS engine checkout is not in a default location, set:

```bash
JS_ENGINE_ROOT=../js-engine bash tools/parity/run_parity.sh
```

Expected success output:

- `PARITY_OK`
- `Parity check passed.`

## Quick Trial Demo

Run a bundled end-to-end trial using:

- Symbol: `AAPL`
- Candles: `10y / 1d`
- Strategy: `SMA crossover 5/20`

```bash
swift run BacktestingKitTrialDemo
```

One-liner API (works in apps, tests, and Swift Playground after importing the package):

```swift
let demoResult = BKEngine.runDemo(dataset: .aapl)
```

The demo emits concise step-by-step logs (load sample CSV, parse, run backtest, summarize metrics).

Bundled demo datasets (10 total across NASDAQ + NYSE):

- `BacktestingKit/Resources/AAPL_10Y_1D.csv`
- `BacktestingKit/Resources/MSFT_10Y_1D.csv`
- `BacktestingKit/Resources/GOOGL_10Y_1D.csv`
- `BacktestingKit/Resources/NVDA_10Y_1D.csv`
- `BacktestingKit/Resources/TSLA_10Y_1D.csv`
- `BacktestingKit/Resources/AMZN_10Y_1D.csv`
- `BacktestingKit/Resources/JPM_10Y_1D.csv`
- `BacktestingKit/Resources/XOM_10Y_1D.csv`
- `BacktestingKit/Resources/WMT_10Y_1D.csv`
- `BacktestingKit/Resources/KO_10Y_1D.csv`

## One-Line End-to-End Engine Calls (V2 / V3)

Run full engine execution in one async call and get either `Result.success` or `Result.failure`.
`BKEngine` is the canonical surface; lower-level drivers are still available.

V3:

```swift
let result = await BKEngine.runV3(
    .init(
        instrument: instrument,
        p1: 5,
        p2: 20,
        dateFormat: "yyyy-MM-dd",
        executionOptions: .init(parserMode: .streamingStrict, csvColumnMapping: nil),
        dataStore: dataStore,
        csvProvider: csvProvider,
        log: { print($0) }
    )
)
```

V2:

```swift
let result = await BKEngine.runV2(
    .init(
        instrumentID: "AAPL",
        config: v2Config,
        p1: 5,
        p2: 20,
        dateFormat: "yyyy-MM-dd",
        csvColumnMapping: nil,
        csvProvider: csvProvider,
        log: { print($0) }
    )
)
```

## Detailed Docs

- `docs/ONBOARDING.md`
- `docs/PACKAGE_USAGE_GUIDE.md`
- `docs/GETTING_STARTED.md`
- `docs/INDEX.md`
- `docs/HELPER_WORKFLOWS.md`
- `docs/ENGINE_GUIDE.md`
- `docs/DATA_INGESTION.md`
- `docs/INDICATORS_STRATEGIES_METRICS.md`
- `docs/TOOLS.md`
- `docs/PARITY_TESTING.md`
- `docs/AGENTIC_USAGE.md`
- `docs/OPEN_SOURCE_MAINTAINERS.md`
- `docs/RELEASE_CHECKLIST.md`

## Open Source Metadata

- License: `LICENSE` (MIT)
- Contribution guide: `CONTRIBUTING.md`
- Code of conduct: `CODE_OF_CONDUCT.md`
- Security policy: `SECURITY.md`
- Support policy: `SUPPORT.md`
- Changelog: `CHANGELOG.md`
- Authors: `AUTHORS.md`
- GitHub templates/workflows: `.github/`
