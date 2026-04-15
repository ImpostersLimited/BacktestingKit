# BacktestingKit Onboarding

This is the canonical markdown tutorial for BacktestingKit. It is written for someone who is new to the package and wants one clear route from “it builds” to “I can integrate this into my app”.

If you want the full docs map instead, start at [INDEX.md](INDEX.md). If you want guided interactive tutorials in Xcode, open `../BacktestingKit/BacktestingKit.docc`.

## What You Will Finish With

By the end of this tutorial you will have:

1. Build the package locally.
2. Run a bundled demo backtest with no API keys and no external setup.
3. Run the package from inline CSV.
4. Understand which top-level surface should own your next integration step.
5. Integrate through `BKAppFacade`.
6. Drop to the canonical `BKEngine` path when direct request control matters.
7. Know which deep-dive guide to read next.

## Step 1: Build the package

From the repo root:

```bash
swift build
```

Success looks like:

- the package builds cleanly from the repo root
- you are ready to run the bundled demo without any external provider setup

What you learned:

- the package can build locally in the simplest supported flow

Where to go next:

- continue to Step 2 for the first offline success path
- if you want Xcode-specific build commands, see [GETTING_STARTED.md](GETTING_STARTED.md)

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
    print(summary.metrics.totalReturn)
case .failure(let error):
    print(error.localizedDescription)
}
```

Success looks like:

- the bundled resources load correctly
- the parser runs
- you get a `BKRunSummary` back and can inspect `summary.metrics.totalReturn`

What you learned:

- `BKEngine.runDemo(...)` is the smallest full end-to-end smoke path
- the package can complete a deterministic backtest offline

Where to go next:

- continue to Step 3 if you want to switch from bundled data to your own CSV
- read [GETTING_STARTED.md](GETTING_STARTED.md) if you only wanted the shortest install/build/run checklist

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

Success looks like:

- your CSV passes preflight and runs through the helper-backed demo flow
- you can move from raw CSV text to a `BKRunSummary` without building a provider type

What you learned:

- preflight user-supplied CSV before execution
- helper workflows are the shortest path while you are still onboarding

Where to go next:

- continue to Step 4 to decide which top-level surface should own your next integration step
- read [DATA_INGESTION.md](DATA_INGESTION.md) if your next task is CSV mapping, date formats, or provider normalization

## Step 4: Understand the surface choice

Before wiring anything deeper, decide which surface owns your next job:

- `BKAppFacade` if your input is user CSV and your output is app UI state
- `BKEngine` if your app already knows the provider shape and wants direct request control
- `BacktestingKitManager` if you already have candles
- tool helpers if the task is validation, export, comparison, scenario generation, or parity

Success looks like:

- you know where to start before writing integration code
- you avoid dropping into `BKEngine` earlier than necessary

What you learned:

- the package has distinct top-level surfaces with different jobs
- beginner integrations should usually start helper-first and app-integrator-first

Where to go next:

- continue to Step 5 if your app starts from reviewed user CSV
- read [CHOOSE_YOUR_SURFACE.md](CHOOSE_YOUR_SURFACE.md) if you want the fuller routing guide across all package surfaces

## Step 5: Integrate through `BKAppFacade`

For first-time app integrations, start with `BKAppFacade`. It is designed for apps that need inspection, preview, validation, normalization, and then execution from pasted, uploaded, or edited CSV.

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

If your app does not know the CSV settings yet, use the explicit auto-inference path instead of guessing in UI code:

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

Success looks like:

- your app can render one review-state payload with issues, preview rows, inferred settings, and readiness
- your app can choose between reviewed and auto-inferred handoff paths without re-implementing import logic

What you learned:

- `BKAppFacade` is the default first production-style integration layer for app-facing import and preset flows
- the package already exposes explicit reviewed and auto-inferred handoff paths

Where to go next:

- continue to Step 6 when you need direct engine request ownership
- read [HELPER_WORKFLOWS.md](HELPER_WORKFLOWS.md) if you want the full façade/helper workflow catalog

## Step 6: Drop to `BKEngine` when you need direct request control

When you are ready to own provider wiring and request construction directly, switch to `BKEngine`. That remains the canonical public execution surface for direct v2/v3 execution.

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

Success looks like:

- your app constructs the request model itself
- `await BKEngine.runV3(...)` or `await BKEngine.runV2(...)` becomes the stable lower-level execution boundary

What you learned:

- `BKEngine` is the canonical direct engine surface
- you only need to drop here once helper/facade workflows stop being expressive enough

Where to go next:

- read [ENGINE_GUIDE.md](ENGINE_GUIDE.md) for full v2/v3 request shapes, one-liners, drivers, and batch orchestration
- read [DATA_INGESTION.md](DATA_INGESTION.md) if your next task is custom provider wiring or CSV normalization rules

## Step 7: Choose your next guide

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
2. [CHOOSE_YOUR_SURFACE.md](CHOOSE_YOUR_SURFACE.md)
3. [HELPER_WORKFLOWS.md](HELPER_WORKFLOWS.md)
4. [ENGINE_GUIDE.md](ENGINE_GUIDE.md)
5. [DATA_INGESTION.md](DATA_INGESTION.md)
6. [INDICATORS_STRATEGIES_METRICS.md](INDICATORS_STRATEGIES_METRICS.md)
7. [TOOLS.md](TOOLS.md)
