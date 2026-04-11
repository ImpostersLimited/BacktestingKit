# 2026-04-09 App CSV Import Facade Design

## Goal

Make app-side CSV import and validation substantially easier without introducing breaking changes or pushing more low-level orchestration burden onto users.

This pass keeps the work on `BKAppFacade` and focuses on CSV-only ingestion flows for app integration.

## Constraints

- Additive only
- No behavior changes to existing parsers, validation rules, engine helpers, or tool helpers
- CSV-oriented only in this pass
- App-facing only
- No file-path or raw `Data` inputs yet
- Reuse existing `BKEngine`, `BKValidationTool`, parser, and export logic rather than forking behavior

## Why This Pass

The package now has:

- low-level CSV parsing and validation
- engine-level CSV execution helpers
- summary/export/comparison helpers
- an app-facing facade (`BKAppFacade`)

What is still awkward for app developers is the import step itself. A UI that lets a user paste or upload CSV still has to decide how to:

- inspect whether the CSV is structurally usable
- preview what the parser will actually produce
- validate that import settings are correct
- normalize parsed data into a stable app-facing report
- run import + validation + preset execution in one step

Those are app workflows, not engine-model workflows, so they fit naturally on `BKAppFacade`.

## Chosen Approach

Keep the expansion on `BKAppFacade`, but make the additions strongly CSV-import-shaped so the namespace grows in a coherent direction.

This keeps the public surface easier to discover:

- `BKAppFacade` remains the place beginners and app integrators start
- `BKEngine` remains the canonical lower-level execution surface
- `BKValidationTool` remains the canonical lower-level validation surface

## New Public Surface

Add these methods on `BKAppFacade`:

- `inspectCSV(symbol:csv:columnMapping:) -> BKAppCSVInspectionReport`
- `previewCSV(symbol:csv:dateFormat:reverse:columnMapping:maxRows:) -> BKAppCSVPreviewReport`
- `validateCSVImport(symbol:csv:dateFormat:reverse:columnMapping:) -> BKAppCSVValidationReport`
- `normalizeCSVImport(symbol:csv:dateFormat:reverse:columnMapping:) -> BKAppCSVNormalizedReport`
- `runCSVImport(symbol:csv:preset:dateFormat:reverse:columnMapping:log:) -> BKAppCSVImportRunReport`
- `runCSVImportAndExportMarkdown(symbol:csv:preset:dateFormat:reverse:columnMapping:title:log:) -> BKAppCSVImportMarkdownReport`

## New Public Models

Add app-facing models under `BacktestingKit/App/`:

- `BKAppCSVInspectionReport`
- `BKAppCSVPreviewRow`
- `BKAppCSVPreviewReport`
- `BKAppCSVValidationReport`
- `BKAppCSVNormalizedReport`
- `BKAppCSVImportRunReport`
- `BKAppCSVImportMarkdownReport`

These models should be lightweight, UI-friendly, and summary-oriented rather than exposing internal parser or engine implementation details directly.

## Behavioral Design

### 1. `inspectCSV(...)`

Purpose:
- answer “is this CSV worth continuing with?”

Should include:
- `symbol`
- whether the CSV appears non-empty
- whether a header was detected
- a row count estimate
- current validation/preflight issues
- `isReady` boolean

Implementation shape:
- delegate to `BKValidationTool.preflightCSV(...)`
- avoid re-parsing more than necessary

### 2. `previewCSV(...)`

Purpose:
- answer “what will this import produce if I continue?”

Should include:
- parsed preview rows, capped by `maxRows`
- total parsed row count
- date range
- first/last close or a compact price range summary
- parse failure if parsing fails
- `isSuccessful`

Implementation shape:
- delegate to existing CSV parsing helpers
- convert parsed bars into a bounded app-facing preview row model

### 3. `validateCSVImport(...)`

Purpose:
- answer “are my import settings and parser assumptions valid?”

Should include:
- the preflight report
- parse success/failure state
- parsed row count when available
- validation issues rolled into one app-facing structure
- `isValid`

Implementation shape:
- use `BKValidationTool.preflightCSV(...)`
- attempt actual parse with the supplied date/reverse/mapping settings
- surface parse errors as structured import validation failures

### 4. `normalizeCSVImport(...)`

Purpose:
- answer “what normalized data do I get if the import succeeds?”

Should include:
- parsed bars
- normalized candles
- compact summary metadata (row count, date range, symbol)
- parse failure if unsuccessful
- `isSuccessful`

Implementation shape:
- parse bars with current CSV helper
- convert to candles with existing helper logic
- package the result in one report

### 5. `runCSVImport(...)`

Purpose:
- provide the one-step app-side import + validation + execution path

Should include:
- import inspection/validation context
- normalized parse metadata if successful
- run summary if successful
- structured failure if unsuccessful
- `isSuccessful`

Implementation shape:
- reuse `validateCSVImport(...)` and/or `normalizeCSVImport(...)`
- delegate actual execution to the existing preset-backed app/engine helper path

### 6. `runCSVImportAndExportMarkdown(...)`

Purpose:
- support onboarding, support/debug UI, or shareable import result reporting

Should include:
- everything from `runCSVImport(...)`
- markdown output when export succeeds
- export error when execution succeeds but markdown export fails

Implementation shape:
- delegate to `runCSVImport(...)`
- delegate markdown generation to the existing export helper

## API Shape Guidelines

To keep the surface coherent:

- use `CSVImport` consistently in method and model naming
- keep methods static on `BKAppFacade`
- default arguments should match current package conventions:
  - `dateFormat: "yyyy-MM-dd"`
  - `reverse: false`
  - `columnMapping: nil`
- preserve `log` callback only on execution-oriented helpers

## File Layout

Additive files:

- `BacktestingKit/App/BKAppImportModels.swift`
  - import-specific app-facing models

Extend:

- `BacktestingKit/App/BKAppFacade.swift`
  - add the new CSV-import-centric helpers

Tests:

- extend `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`
  - or split into `BacktestingKitAppImportFacadeTests.swift` if it becomes too large

## Testing Strategy

Add focused coverage for:

- inspection success on valid CSV
- inspection failure/readiness on empty or malformed CSV
- preview truncation via `maxRows`
- preview with custom column mapping
- validation failure for invalid date format / malformed rows
- normalization success returning bars and candles
- import run success returning summary
- import run failure preserving structured diagnostics
- markdown export path succeeding after import run

Then run:

- targeted facade/import tests
- full `swift test`

## Documentation Updates

Update:

- `README.md`
- `docs/ONBOARDING.md`
- `docs/GETTING_STARTED.md`
- `docs/HELPER_WORKFLOWS.md`
- `docs/PACKAGE_USAGE_GUIDE.md`
- `docs/API_REFERENCE.md`

Docs should present this as:

- the easiest app-side CSV import path
- a bridge between “user pasted/imported CSV” and “run a strategy”
- additive convenience, not a replacement for `BKEngine`

## Non-Goals

Not in this pass:

- file-path imports
- `Data`-backed imports
- multi-file import bundles
- manager-facing ingestion helpers
- changing parser behavior or validation semantics
- adding persistence/storage behavior to import helpers

## Acceptance Criteria

This pass is complete when:

- `BKAppFacade` exposes a coherent CSV import helper family
- import inspection, preview, validation, normalization, and execution are each available as app-facing helpers
- existing behavior is unchanged
- targeted tests and full `swift test` pass
- docs point beginners/app integrators to the new import path
