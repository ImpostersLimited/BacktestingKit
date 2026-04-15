# Getting Started

Use this page when you already know you want the shortest path from clone to first successful run.

If you are new to BacktestingKit, start at `ONBOARDING.md` instead. If you want the full docs map, start at `INDEX.md`.

## Requirements

- Xcode with Swift toolchain support for this project.
- macOS environment with command-line tools installed.
- Optional: Node.js + local JS engine checkout for parity checks in `tools/parity`.

## Build and Verify

```bash
swift build
swift test
```

If you prefer Xcode-based verification:

```bash
xcodebuild -scheme BacktestingKit -project BacktestingKit.xcodeproj -configuration Debug build
```

## Fastest First Success

Run the bundled demo path:

```swift
import BacktestingKit

let result = BKEngine.runDemo(dataset: .aapl)
```

Success looks like:

- the package builds and tests cleanly
- the bundled CSV resources load without external setup
- you can inspect `summary.metrics.totalReturn` from the returned `BKRunSummary`

You can also run the trial demo from the command line:

```bash
swift run BacktestingKitTrialDemo
```

## Core Entry Points

Use these as the main top-level surfaces:

- `BKAppFacade`
  Start here for app-facing CSV import/review screens, preset-backed flows, and beginner-friendly integration.
- `BKEngine`
  Use this for canonical direct v2/v3 request-model execution and provider-driven data access.
- `BacktestingKitManager`
  Use this when you already have candles and want manager-owned indicator, strategy, and report helpers.
- Tool helpers
  Use `BKValidationTool`, `BKExportTool`, `BKComparisonTool`, `BKScenarioTool`, and `BKParityTool` for validation, export, comparison, scenarios, and parity.

## Shortest Routes by Task

- User CSV -> app UI review state:
  `BKAppFacade.buildCSVImportScreenState(...)`
- User CSV -> reviewed execution:
  `BKAppFacade.runConfirmedCSVImport(...)`
- Inline CSV -> helper-backed smoke test:
  `BKEngine.runDemoCSV(...)`
- Explicit v3 request:
  `await BKEngine.runV3(...)`
- Explicit v2 request:
  `await BKEngine.runV2(...)`

## What To Read Next

- New to the package: `ONBOARDING.md`
- Choosing between surfaces: `CHOOSE_YOUR_SURFACE.md`
- Helper and façade workflows: `HELPER_WORKFLOWS.md`
- Canonical engine flows: `ENGINE_GUIDE.md`
- CSV/provider details: `DATA_INGESTION.md`
- Full documentation map: `INDEX.md`
