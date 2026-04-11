# App CSV Import Facade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a CSV-oriented app-facing import helper family on `BKAppFacade` so apps can inspect, preview, validate, normalize, run, and export pasted CSV data with minimal orchestration.

**Architecture:** Keep the new surface additive and app-facing by extending `BKAppFacade` and introducing import-specific report models under `BacktestingKit/App/`. Delegate all actual parsing, validation, summary building, and export work to the existing CSV helpers, `BKValidationTool`, `BKEngine`, `BKQuickDemo`, and `BKExportTool` so behavior stays aligned with the current package.

**Tech Stack:** Swift, XCTest, existing BacktestingKit parser/validation/engine/export helpers

---

## File Map

- Create: `BacktestingKit/App/BKAppImportModels.swift`
  - App-facing report and preview row models for CSV import workflows
- Modify: `BacktestingKit/App/BKAppFacade.swift`
  - Add CSV import helper methods
- Modify: `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`
  - Add focused coverage for the new import helpers
- Modify: `README.md`
  - Add a short app-side CSV import example
- Modify: `docs/ONBOARDING.md`
  - Point beginners to the CSV import helper path
- Modify: `docs/GETTING_STARTED.md`
  - Include the CSV import helper family in the fast-start surface
- Modify: `docs/HELPER_WORKFLOWS.md`
  - Document the new import helper family
- Modify: `docs/PACKAGE_USAGE_GUIDE.md`
  - Add the import path to the package usage map
- Modify: `docs/API_REFERENCE.md`
  - Add the new models and helper methods
- Modify: `tasks/todo.md`
  - Track execution and add review notes

### Task 1: Add Import Model Layer

**Files:**
- Create: `BacktestingKit/App/BKAppImportModels.swift`
- Test: `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`

- [ ] **Step 1: Add the new CSV import report models**

Create lightweight app-facing models:
- `BKAppCSVInspectionReport`
- `BKAppCSVPreviewRow`
- `BKAppCSVPreviewReport`
- `BKAppCSVValidationReport`
- `BKAppCSVNormalizedReport`
- `BKAppCSVImportRunReport`
- `BKAppCSVImportMarkdownReport`

Keep them `Codable`/`Equatable`/`Sendable` where the contained types allow it, and shape them around app/UI usage rather than internal parser details.

- [ ] **Step 2: Add only fields that existing helpers can produce cleanly**

Use existing package outputs for:
- preflight/readiness
- parsed row counts
- date ranges
- preview rows
- normalized bars/candles
- run summaries
- export failures

Avoid inventing new parser semantics or derived heuristics that would drift from current behavior.

- [ ] **Step 3: Run a compile-focused target check**

Run: `swift test --filter BacktestingKitAppFacadeTests`

Expected:
- the package compiles with the new model file even before all new tests are added

### Task 2: Extend `BKAppFacade` with CSV Import Helpers

**Files:**
- Modify: `BacktestingKit/App/BKAppFacade.swift`
- Modify: `BacktestingKit/App/BKAppImportModels.swift`
- Test: `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`

- [ ] **Step 1: Add `inspectCSV(...)`**

Implement:
- `inspectCSV(symbol:csv:columnMapping:) -> BKAppCSVInspectionReport`

Delegate to:
- `BKValidationTool.preflightCSV(...)`

Return app-facing readiness, issue list, row-count/date-range metadata that already exists in preflight output.

- [ ] **Step 2: Add `previewCSV(...)`**

Implement:
- `previewCSV(symbol:csv:dateFormat:reverse:columnMapping:maxRows:) -> BKAppCSVPreviewReport`

Delegate to the current CSV parsing helpers, then convert the first `maxRows` parsed bars into preview rows with bounded metadata.

- [ ] **Step 3: Add `validateCSVImport(...)`**

Implement:
- `validateCSVImport(symbol:csv:dateFormat:reverse:columnMapping:) -> BKAppCSVValidationReport`

Use:
- preflight validation first
- actual parse attempt second

Return one app-facing validation bundle that explains whether import settings are usable.

- [ ] **Step 4: Add `normalizeCSVImport(...)`**

Implement:
- `normalizeCSVImport(symbol:csv:dateFormat:reverse:columnMapping:) -> BKAppCSVNormalizedReport`

Parse bars, convert them to candles using existing helper logic, and package normalized outputs plus summary metadata.

- [ ] **Step 5: Add `runCSVImport(...)`**

Implement:
- `runCSVImport(symbol:csv:preset:dateFormat:reverse:columnMapping:log:) -> BKAppCSVImportRunReport`

Compose:
- inspection/validation context
- normalized import metadata
- preset-backed execution through the existing app/engine helper path

- [ ] **Step 6: Add `runCSVImportAndExportMarkdown(...)`**

Implement:
- `runCSVImportAndExportMarkdown(symbol:csv:preset:dateFormat:reverse:columnMapping:title:log:) -> BKAppCSVImportMarkdownReport`

Compose:
- `runCSVImport(...)`
- `exportMarkdownSummary(...)`

### Task 3: Add Focused CSV Import Tests

**Files:**
- Modify: `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`

- [ ] **Step 1: Add inspection tests**

Cover:
- valid CSV inspection
- empty/malformed CSV inspection failure/readiness

- [ ] **Step 2: Add preview tests**

Cover:
- preview row truncation with `maxRows`
- custom column mapping preview path

- [ ] **Step 3: Add validation and normalization tests**

Cover:
- invalid date / malformed row validation failure
- normalization success returning bars and candles

- [ ] **Step 4: Add import execution tests**

Cover:
- `runCSVImport(...)` success
- `runCSVImport(...)` structured failure
- `runCSVImportAndExportMarkdown(...)` success

- [ ] **Step 5: Run the targeted test suite**

Run: `swift test --filter BacktestingKitAppFacadeTests`

Expected:
- all facade tests pass

### Task 4: Update User-Facing Docs

**Files:**
- Modify: `README.md`
- Modify: `docs/ONBOARDING.md`
- Modify: `docs/GETTING_STARTED.md`
- Modify: `docs/HELPER_WORKFLOWS.md`
- Modify: `docs/PACKAGE_USAGE_GUIDE.md`
- Modify: `docs/API_REFERENCE.md`

- [ ] **Step 1: Add a short CSV import example to the README**

Show the shortest “paste CSV and get a run/export” flow.

- [ ] **Step 2: Update onboarding/getting-started guides**

Position the new CSV import helper family as:
- the easiest app-side import path
- the bridge between pasted CSV and strategy execution

- [ ] **Step 3: Expand helper/package/API docs**

Document:
- each new `BKAppFacade` CSV import method
- each new import-specific model

- [ ] **Step 4: Run a docs discoverability scan**

Run:
- `rg -n "inspectCSV|previewCSV|validateCSVImport|normalizeCSVImport|runCSVImport|runCSVImportAndExportMarkdown" README.md docs BacktestingKit/BacktestingKit.docc`

Expected:
- the new import helper family appears in the main user-facing docs

### Task 5: Full Verification and Review Notes

**Files:**
- Modify: `tasks/todo.md`

- [ ] **Step 1: Run the full package test suite**

Run: `swift test`

Expected:
- full package test suite passes with no regressions

- [ ] **Step 2: Mark the checklist complete**

Update `tasks/todo.md` for the CSV import facade pass.

- [ ] **Step 3: Add review notes**

Record:
- files added/modified
- helper family delivered
- verification commands run
- any residual non-goals explicitly left out
