# Helper Expansion Third Pass Plan

## Goal

Add the remaining high-value additive helper APIs discussed after the first two helper passes, with no breaking changes to the current public surface.

## Requested Helper Coverage

1. `BKEngine.runPresetCSV(...)`
2. `BKEngine.runPreset(dataset:preset:)`
3. `BKEngine.preflightAndRunCSV(...)`
4. `BKEngine.runV2ValidatedCSV(...)`
5. `BKEngine.runV3ValidatedCSV(...)`
6. `BacktestingKitManager.parseAndRunRecipe(...)`
7. `BacktestingKitManager.runRecipeReport(...)`
8. `BacktestingKitManager.applyDefaultScreeningBundle(...)`
9. `BKComparisonTool.assertEquivalent(...)`
10. `BKExportTool.exportMarkdownSummary(...)`
11. `BKScenarioTool.smokeSuite(...)`

Note: Items 4 and 5 are the split implementation of the originally requested validated v2/v3 engine helpers.

## Design Constraints

- Additive only. No renames, removals, or behavior changes to existing helpers.
- Reuse existing parsing, preset, validation, summary, export, and scenario code paths wherever possible.
- Prefer structured helper result models for validation-heavy workflows so callers keep preflight context on failure.
- Keep new helpers shallow wrappers over current primitives instead of adding a second execution stack.

## Planned API Shape

### Engine

- Add preset-backed CSV convenience helpers that reuse `BKQuickDemo` parsing and `BKPresetCatalog`.
- Add bundled dataset + preset wrapper on `BKEngine` so app users can stay on the engine surface.
- Add validation-aware engine helper result models that include:
  - CSV preflight report
  - request-shape validation report
  - success payload when execution succeeds
  - typed `BKEngineFailure` when execution fails

### Manager

- Add CSV-to-candles recipe execution helper.
- Add a report bundle that packages:
  - raw `BacktestResult`
  - `BKRunSummary`
  - `BKManagerReportSnapshot`
  - `BKAdvancedPerformanceMetrics`
- Add a default screening indicator bundle that composes the existing trend, momentum, and volatility helpers.

### Tools

- Add `assertEquivalent(...)` as a throwing wrapper over `compareRuns(...)`.
- Add markdown summary export for tutorials, issue attachments, and lightweight reports.
- Add a deterministic smoke suite that validates and summarizes a small matrix of scenario configs.

## Verification Plan

- Extend engine helper tests for preset CSV runs and validated v2/v3 workflows.
- Extend manager helper tests for CSV recipe parsing, recipe report bundling, and default screening bundles.
- Extend tool helper tests for comparison assertions, markdown export, and smoke suite output.
- Run targeted helper test classes, then full `swift test`.
- Refresh helper and API docs after implementation and scan for the new helper names.
