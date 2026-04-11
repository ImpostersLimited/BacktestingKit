# Choose Your Surface

Use this guide when you are not sure whether to start with `BKAppFacade`, `BKEngine`, `BacktestingKitManager`, or the tool helpers.

## Start with `BKAppFacade`

Use `BKAppFacade` when you are building an app and want the shortest path from user input to a usable backtesting workflow.

Choose it for:

- CSV import and review screens
- onboarding flows
- preset-backed execution from pasted or uploaded CSV
- app-facing export/comparison helpers
- a single namespace for beginner integration

Start here first when your app needs:

- `buildCSVImportScreenState(...)`
- `runConfirmedCSVImport(...)`
- `detectCSVImportSettings(...)`
- `runCSVImportAuto(...)`
- `runPresetCSVAndExportMarkdown(...)`

## Drop to `BKEngine`

Use `BKEngine` when you need direct request-model control over v2 or v3 execution.

Choose it for:

- explicit `V2Request` or `V3Request` construction
- provider-driven data access
- direct engine execution from app code
- canonical request/response ownership

Start here when your app already knows:

- the provider shape
- the request configuration
- whether it wants the v2 or v3 path

## Use `BacktestingKitManager`

Use `BacktestingKitManager` when you are already working with candles and want candle-first composition.

Choose it for:

- indicator bundles
- strategy recipes
- summary/report building over `Candlestick` arrays
- manager-owned screening and metrics helpers

Do not start here for CSV import UI work. Use `BKAppFacade` or `BKEngine` first.

## Use the Tool Helpers

Use the tool helpers when you need validation, diagnostics, export, comparison, scenario generation, or parity workflows.

Primary surfaces:

- `BKValidationTool`
- `BKDiagnosticsCollector`
- `BKExportTool`
- `BKComparisonTool`
- `BKScenarioTool`
- `BKParityTool`

Choose them for:

- import preflight
- support/debug payloads
- markdown or bundle export
- regression comparison
- deterministic smoke scenarios
- parity checks

## Recommended Order for New Users

1. Start with `BKAppFacade` for app-facing CSV import and preset helpers.
2. Move to `BKEngine` when you need explicit request-level control.
3. Use `BacktestingKitManager` when you already have candles and want composition.
4. Add tool helpers when you need validation, diagnostics, export, or comparison.

## Fast Rule of Thumb

- If the input is user CSV and the output is app UI state, start with `BKAppFacade`.
- If the input is an engine request, start with `BKEngine`.
- If the input is candles, start with `BacktestingKitManager`.
- If the task is validation/export/comparison/scenario/parity, start with the tool helpers.
