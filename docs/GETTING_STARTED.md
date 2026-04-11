# Getting Started

For the linear beginner path, start at `docs/ONBOARDING.md`. For the full documentation map, start at `docs/INDEX.md`. For a complete package usage map, read `docs/PACKAGE_USAGE_GUIDE.md`.

## Requirements

- Xcode with Swift toolchain support for this project.
- macOS environment with command-line tools installed.
- Optional: Node.js + local JS engine checkout for parity checks in `tools/parity`.

## Build

```bash
xcodebuild -scheme BacktestingKit -project BacktestingKit.xcodeproj -configuration Debug build
```

## Core Entry Points

`BKAppFacade` is the shortest app-facing entrypoint for beginners and integrations. `BKEngine` remains the canonical public entrypoint when you want direct engine request-model control.

- `BKAppFacade.runPresetCSVAndExportMarkdown(...)`
  Run a preset-backed inline CSV workflow and get a human-readable Markdown summary in one call.
- `BKAppFacade.buildCSVImportScreenState(...)`
  Build one app-facing import-review payload with inspection, inference, preview, validation, normalization, grouped issues, and readiness.
- `BKAppFacade.runConfirmedCSVImport(...)`
  Hand off reviewed CSV import state into execution without reconstructing settings in app code.
- `BKAppFacade.inspectCSV(...)`, `previewCSV(...)`, `validateCSVImport(...)`, `normalizeCSVImport(...)`, `runCSVImport(...)`
  App-side CSV import and validation flow for onboarding, import screens, and simple preset execution.
- `BKAppFacade.detectCSVImportSettings(...)`, `previewCSVAuto(...)`, `validateCSVImportAuto(...)`, `normalizeCSVImportAuto(...)`, `runCSVImportAuto(...)`
  App-side CSV import flow when the app does not know the settings yet and wants safe inference plus explicit reporting.
- `BKAppFacade.runScenarioAndExportBundle(...)`
  Run a deterministic scenario and export a portable bundle for app diagnostics or sample data flows.

`BKEngine` is the canonical public entrypoint for engine usage.

- `BKEngine.runV3(...)` for v3 one-shot execution.
- `BKEngine.runV2(...)` for v2 one-shot execution.
- `BKEngine.runDemo(...)` for bundled quick validation.

Lower-level entrypoints remain available for advanced usage:

- V3 driver: `BKSimulationDriver`
- V2 driver: `BKV2SimulationDriver`
- V3 simulate: `v3simulateConfig`
- V2 simulate: `v2simulateConfig`

## Fastest Helper Paths

For app integration and smoke workflows, prefer the additive helper layer before dropping to raw driver setup.

- `BKAppFacade.runPresetCSVAndExportMarkdown(...)`
  Start from one app-facing helper namespace for execution plus export.
- `BKAppFacade.runCSVImport(...)`
  Validate, normalize, and execute user-supplied CSV through a preset in one app-facing path.
- `BKAppFacade.runCSVImportAuto(...)`
  Infer safe CSV settings, normalize descending input when needed, and execute without pushing inference logic into app code.
- `BKAppFacade.runConfirmedCSVImport(...)`
  Execute from review-state or explicit user-confirmed settings after the import screen step.
- `BKAppFacade.previewCSV(...)`
  Build a bounded app-side preview before deciding whether to persist or run imported CSV.
- `BKAppFacade.previewCSVAuto(...)`
  Build the same preview when the app needs settings inference first.
- `BKAppFacade.runScenarioAndExportBundle(...)`
  Generate a deterministic scenario and package the artifacts for app-facing workflows.
- `BKEngine.runDemoCSV(...)`
  Run inline CSV through the built-in SMA crossover demo path.
- `BKEngine.runV2CSV(...)` / `BKEngine.runV3CSV(...)`
  Execute v2/v3 requests from inline CSV without building a provider type.
- `BKQuickDemo.runBundledPresetDemo(...)`
  Run one bundled dataset through a preset-backed helper flow.
- `BKQuickDemo.runBundledSmokeMatrix(...)`
  Execute the same preset across a deterministic demo dataset matrix.
- `BacktestingKitManager.runSMACrossoverSummary(...)`
  Produce a compact `BKRunSummary` from a manager-owned strategy workflow.
- `BKValidationTool.preflightCSV(...)`
  Validate CSV and capture row count plus date range for onboarding UIs.
- `BKScenarioTool.runExportBundle(...)`
  Generate a deterministic scenario, summarize it, and export bundle artifacts.

## Minimal Helper Workflow

```swift
let csv = """
timestamp,open,high,low,close,volume
2024-01-01,100,101,99,100.5,1000000
2024-01-02,100.5,102,100,101.5,1100000
"""

let preflight = BKValidationTool.preflightCSV(csv, symbol: "AAPL")
guard preflight.isReady else { return }

let demo = BKEngine.runDemoCSV(symbol: "AAPL", csv: csv)
let importScreen = BKAppFacade.buildCSVImportScreenState(
    symbol: "AAPL",
    csv: csv,
    maxRows: 2
)
let importPreview = BKAppFacade.previewCSV(symbol: "AAPL", csv: csv, maxRows: 2)
let importAuto = BKAppFacade.previewCSVAuto(symbol: "AAPL", csv: csv, maxRows: 2)

switch demo {
case .success(let summary):
    print(summary.symbol)
case .failure(let error):
    print(error.localizedDescription)
}
```

If you are new to the package, do the bundled demo onboarding step first in `docs/ONBOARDING.md`, then come back here for the rest of the setup and execution details.

## Minimal V3 Flow

1. Get raw CSV data (`BKRawCsvProvider` or custom provider).
2. Parse to bars (`csvToBars` or `csvToBarsStreaming`).
3. Build rules/config models (`BKV3_*`).
4. Run simulation via `BKSimulationDriver` or direct `v3simulateConfig`.
5. Run post-analysis (`v3postAnalysis`) if needed.

## Batch Simulation

Use `simulateInstrumentsWithDetailedReport(...)` to get:

- Per-instrument reports.
- Structured failures (`BKEngineFailure`) with error stage/code metadata.
- Progress callback support via `BKSimulationProgress`.

## Notes

- Keep v2/v3 models unchanged if you need strict JavaScript parity.
- For custom sources, normalize CSV before parsing and preserve chronological order.
- Full parity requires a local JS engine path (`../js-engine`, `../algotrade-js-trial`, or `JS_ENGINE_ROOT`).
- The helper workflow catalog is documented in `docs/HELPER_WORKFLOWS.md`.
- The linear onboarding path is documented in `docs/ONBOARDING.md`.
- The full package workflow map is documented in `docs/PACKAGE_USAGE_GUIDE.md`.
