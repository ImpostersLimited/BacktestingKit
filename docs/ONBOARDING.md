# BacktestingKit Onboarding

This guide is the fastest beginner path through the package. It is written for someone who is new to BacktestingKit and wants one clear route from “it builds” to “I can integrate this into my app”.

If you want the full docs map instead, start at [INDEX.md](INDEX.md). If you want the workflow-oriented package map, read [PACKAGE_USAGE_GUIDE.md](PACKAGE_USAGE_GUIDE.md).

## What you will do

In this onboarding flow you will:

1. Build the package locally.
2. Run a bundled demo backtest with no API keys and no external setup.
3. Run the package from inline CSV.
4. Learn the app-facing CSV import/validation flow.
5. Move into the canonical app-facing `BKEngine` integration shape.
6. Branch into the deeper guide that matches your next task.

## Step 1: Build the package

From the repo root:

```bash
swift build
```

If you prefer Xcode-based verification, see [GETTING_STARTED.md](GETTING_STARTED.md).

## Step 2: Prove the package works offline

The safest first success is the bundled demo path. It uses packaged CSV resources, so there is no provider wiring and no vendor dependency.

```swift
import BacktestingKit

let result = BKEngine.runDemo(dataset: .aapl) { line in
    print(line)
}

switch result {
case .success(let summary):
    print(summary.symbol)
    print(summary.barCount)
    print(summary.result.totalReturn)
case .failure(let error):
    print(error.localizedDescription)
}
```

When this works, you know:

- the package builds
- the bundled resources load correctly
- the parser runs
- the default strategy flow can complete end-to-end

## Step 3: Run your own inline CSV

Once the bundled demo works, the next easiest step is inline CSV. This is the shortest route for tests, prototypes, and onboarding UIs.

```swift
let csv = """
timestamp,open,high,low,close,volume
2024-01-01,100,101,99,100.5,1000000
2024-01-02,100.5,102,100,101.5,1100000
2024-01-03,101.5,103,101,102.0,1200000
"""

let preflight = BKValidationTool.preflightCSV(csv, symbol: "AAPL")
guard preflight.isReady else {
    print(preflight.validation.issues)
    fatalError("CSV failed preflight")
}

let result = BKEngine.runDemoCSV(symbol: "AAPL", csv: csv)
```

Use this stage to learn two habits early:

- preflight data before execution when onboarding user-supplied CSV
- stay on helper workflows until you need lower-level control

## Step 4: Learn the app-facing CSV import path

If your app lets users paste, upload, or edit CSV before running a backtest, stay on `BKAppFacade` first. The CSV import helpers are designed for app UIs that need inspection, preview, validation, normalization, and then execution.

```swift
let screenState = BKAppFacade.buildCSVImportScreenState(
    symbol: "AAPL",
    csv: csv,
    maxRows: 3
)

guard screenState.isReadyToContinue else {
    print(screenState.issues)
    fatalError("Import is not ready")
}

let confirmedRun = BKAppFacade.runConfirmedCSVImport(
    from: screenState,
    csv: csv,
    preset: .smaCrossover
)
```

If your app does not know the CSV settings yet, use the explicit auto-inference path instead of guessing in UI code. The auto helpers infer only safe defaults, report what they inferred, and still let your app surface or override those settings.

```swift
let inference = BKAppFacade.detectCSVImportSettings(
    symbol: "AAPL",
    csv: csv
)

let autoPreview = BKAppFacade.previewCSVAuto(
    symbol: "AAPL",
    csv: csv,
    maxRows: 3
)

let autoRun = BKAppFacade.runCSVImportAuto(
    symbol: "AAPL",
    csv: csv,
    preset: .smaCrossover
)
```

Use this layer when you need:

- one stable review-state payload for onboarding/import screens
- grouped issues and readiness for app-side error display
- one clean handoff from reviewed settings into confirmed execution
- normalized bars/candles before deciding whether to persist or run
- one-step import plus preset execution for simple app flows
- a safe auto-apply path when the app does not already know the column mapping, date format, or chronological direction

## Step 5: Move into canonical app integration

When you are ready to wire BacktestingKit into a real app, start with `BKAppFacade` for the shortest app-facing path, then drop to `BKEngine` when you need direct request-model control.

### Facade-first app integration

```swift
let report = BKAppFacade.runPresetCSVAndExportMarkdown(
    symbol: "AAPL",
    csv: csv,
    preset: .smaCrossover
)

if report.isSuccessful {
    print(report.markdown ?? "")
}
```

Use `BKAppFacade` when you want:

- one namespace for preset, scenario, export, and comparison helpers
- a beginner-friendly app integration entrypoint
- delegated workflows that still rely on the canonical engine/tool surfaces underneath

### Canonical engine shape

When you need request-level control, switch to `BKEngine`. That remains the canonical public execution surface for direct v2/v3 execution.

### v3 shape

```swift
struct DemoProvider: BKRawCsvProvider {
    let csv: String

    func getRawCsv(ticker: String, p1: Double, p2: Double) async -> Result<String, Error> {
        .success(csv)
    }
}

let provider = DemoProvider(csv: csv)

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

### v2 shape

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

At this point you have graduated from onboarding and can treat the package as an app integration dependency rather than a demo environment.

## Step 6: Choose your next guide

After this onboarding path, use the guide that matches your next task:

- [CHOOSE_YOUR_SURFACE.md](CHOOSE_YOUR_SURFACE.md) to decide when to stay on `BKAppFacade` and when to drop lower
- [GETTING_STARTED.md](GETTING_STARTED.md) for build/test/run setup details
- [HELPER_WORKFLOWS.md](HELPER_WORKFLOWS.md) for `BKAppFacade`, CSV import, demo, preset, scenario, and smoke helpers
- [ENGINE_GUIDE.md](ENGINE_GUIDE.md) for canonical `BKEngine`, one-liners, drivers, and batch execution
- [DATA_INGESTION.md](DATA_INGESTION.md) for CSV parsing, custom mappings, providers, and data normalization
- [INDICATORS_STRATEGIES_METRICS.md](INDICATORS_STRATEGIES_METRICS.md) for `BacktestingKitManager`, indicators, recipes, and reports
- [TOOLS.md](TOOLS.md) for validation, diagnostics, export, comparison, benchmarking, scenario, and parity helpers
- [EXTENDING_BACKTESTINGKIT.md](EXTENDING_BACKTESTINGKIT.md) for extension points

## Recommended learning order

If you want a structured sequence after onboarding:

1. [GETTING_STARTED.md](GETTING_STARTED.md)
2. [HELPER_WORKFLOWS.md](HELPER_WORKFLOWS.md)
3. [ENGINE_GUIDE.md](ENGINE_GUIDE.md)
4. [DATA_INGESTION.md](DATA_INGESTION.md)
5. [INDICATORS_STRATEGIES_METRICS.md](INDICATORS_STRATEGIES_METRICS.md)
6. [TOOLS.md](TOOLS.md)
