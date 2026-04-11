# CSV Import Diagnostics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a single developer-facing `BKAppFacade.diagnoseCSVImport(...)` helper that reports CSV import stage decisions, inferred/effective settings, and bounded row-level failure examples without changing any existing API behavior.

**Architecture:** Extend the existing app-facing CSV import facade rather than creating a second diagnostics namespace. Build diagnostics as a pure orchestration layer over the current inspection, inference, preview, validation, and normalization helpers, and keep the public result compact by returning summaries and representative failure rows instead of full review-state payloads.

**Tech Stack:** Swift, XCTest, existing `BKAppFacade` CSV import helpers, existing validation/inference models, Markdown docs

---

## File Structure

- Modify: `BacktestingKit/App/BKAppImportModels.swift`
  - Add diagnostics report and supporting stage/failure models
- Modify: `BacktestingKit/App/BKAppFacade.swift`
  - Add `diagnoseCSVImport(...)`
  - Add private helpers for stage decisions, summaries, and row-failure extraction
- Modify: `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`
  - Add focused diagnostics coverage
- Modify: `README.md`
  - Add one short diagnostics example in the app-facing CSV section
- Modify: `docs/HELPER_WORKFLOWS.md`
  - Document when to use diagnostics vs import-review state
- Modify: `docs/PACKAGE_USAGE_GUIDE.md`
  - Add diagnostics to the app-side CSV workflow section
- Modify: `docs/API_REFERENCE.md`
  - Add the diagnostics helper and new public models

## Task 1: Add Diagnostics Models

**Files:**
- Modify: `BacktestingKit/App/BKAppImportModels.swift`
- Test: `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`

- [ ] **Step 1: Add the new diagnostics model declarations**

Add:
- `BKAppCSVImportDiagnosticsReport`
- `BKAppCSVImportStageDecision`
- `BKAppCSVImportDiagnosticStage`
- `BKAppCSVImportStageOutcome`
- `BKAppCSVImportFailureStage`
- `BKAppCSVRowFailureExample`
- compact summary types if not already present for preview/normalization reporting

- [ ] **Step 2: Keep the models consistent with the existing app-facing conventions**

Requirements:
- `public`
- `Equatable`
- `Sendable`
- `Codable` where reasonable and consistent with existing surrounding models
- simple stored properties only
- doc comments matching the style already used in `BKAppImportModels.swift`

- [ ] **Step 3: Build the package to catch model-surface mistakes early**

Run:

```bash
swift test --filter BacktestingKitAppFacadeTests
```

Expected:
- compile succeeds or fails only on the missing diagnostics helper implementation

## Task 2: Add the Diagnostics Helper

**Files:**
- Modify: `BacktestingKit/App/BKAppFacade.swift`
- Test: `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`

- [ ] **Step 1: Add `BKAppFacade.diagnoseCSVImport(...)`**

Signature:

```swift
public static func diagnoseCSVImport(
    symbol: String,
    csv: String,
    maxFailureRows: Int = 5
) -> BKAppCSVImportDiagnosticsReport
```

Implementation constraints:
- additive only
- no changes to existing helper signatures or behavior
- compose the current facade helpers instead of creating a parallel parsing stack

- [ ] **Step 2: Implement stage-order orchestration**

The helper should evaluate in this order:
1. `inspectCSV(...)`
2. `detectCSVImportSettings(...)`
3. `previewCSVAuto(...)` when safe to attempt a structural preview
4. `validateCSVImportAuto(...)` when preview/configuration state is safe enough to continue
5. `normalizeCSVImportAuto(...)` when validation indicates the rows can be normalized safely

Stage-gating rules must be explicit in code:
- preview should be attempted whenever inspection and the raw CSV state are sufficient to try parsing without inventing settings
- validation should be attempted whenever preview/configuration produced a safe continuation path, even if earlier stages emitted warnings
- normalization should be attempted whenever validation succeeds enough to indicate the parsed rows are usable for normalization
- skipped stages must be recorded explicitly instead of implied

Add exactly one stage decision for each of:
- inspection
- inference
- preview
- validation
- normalization

- [ ] **Step 3: Implement failure-stage selection**

Rules:
- the first decisive stage failure becomes `failureStage`
- warnings and fallbacks do not set `failureStage`
- skipped stages should be explicit in `stageDecisions`

- [ ] **Step 4: Implement preview and normalization summaries**

Keep them compact:
- preview summary: row count, date range if available, effective settings used
- normalization summary: normalized row count, first/last timestamps if available, ordering-normalized note if relevant

- [ ] **Step 5: Implement bounded row-failure extraction**

Requirements:
- respect `maxFailureRows`
- prefer concrete raw rows from preview/validation/normalization failures
- return `[]` when no representative row examples are available
- do not fabricate raw rows or synthetic parse content

- [ ] **Step 6: Implement viability computation**

`isImportViable` should only be `true` when:
- validation succeeds, and
- the collected diagnostics indicate the CSV is practically usable for the downstream import path

This rule must not be stricter than the approved design. Do not require every later stage to succeed if the diagnostics already show a developer-usable import path.

- [ ] **Step 7: Run focused tests to compile the helper path**

Run:

```bash
swift test --filter BacktestingKitAppFacadeTests
```

Expected:
- compile succeeds
- diagnostics-specific tests may still fail until added

- [ ] **Step 8: Wrap unexpected internal stage failures into structured diagnostics**

Requirements:
- preserve already-collected diagnostics
- record a failed stage decision at the throwing stage
- set `failureStage`
- return a partial diagnostics report instead of crashing ordinary developer debugging flows
- keep the public API additive-only

## Task 3: Add Focused Diagnostics Tests

**Files:**
- Modify: `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`

- [ ] **Step 1: Add a success-path diagnostics test**

Cover:
- all expected stages appear
- `failureStage == nil`
- `isImportViable == true`
- summaries are populated

- [ ] **Step 2: Add an inference-ambiguity diagnostics test**

Cover:
- inference stage reports warning
- effective settings still exist
- diagnostics continue beyond inference when safe

- [ ] **Step 3: Add a preview-stage failure diagnostics test**

Use malformed CSV that fails during preview/configuration and assert:
- `failureStage == .preview`
- row failures are captured when concrete failing rows are available
- row index/raw row/message are populated when present

- [ ] **Step 4: Add a validation-stage failure diagnostics test**

Use malformed CSV that passes earlier setup but fails validation and assert:
- `failureStage == .validation`
- `isImportViable == false`
- row failures are captured when concrete failing rows are available

- [ ] **Step 5: Add a normalization-stage failure diagnostics test**

Cover:
- preview and validation stage decisions remain available
- `failureStage == .normalization` when normalization is the first decisive failure
- `normalizationSummary == nil`

- [ ] **Step 6: Add a bounded-row-failure test**

Use multiple failing rows and assert:
- `rowFailures.count <= maxFailureRows`

- [ ] **Step 7: Add an additive-regression test for existing helpers**

Cover:
- existing manual or auto CSV helpers still return their prior expected behavior
- the diagnostics helper is additive and does not alter current app-facing CSV flows

- [ ] **Step 8: Add an unexpected-error retention test**

Goal:
- prove earlier stage decisions remain available even when an internal stage throws unexpectedly
- guarantee the structured-partial-diagnostics behavior required by the approved spec

- [ ] **Step 9: Run the focused app-facade test target**

Run:

```bash
swift test --filter BacktestingKitAppFacadeTests
```

Expected:
- PASS

## Task 4: Update App-Facing Documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/HELPER_WORKFLOWS.md`
- Modify: `docs/PACKAGE_USAGE_GUIDE.md`
- Modify: `docs/API_REFERENCE.md`

- [ ] **Step 1: Add a short README diagnostics example**

Position it as:
- developer-facing debugging for CSV import issues
- distinct from `buildCSVImportScreenState(...)`

- [ ] **Step 2: Update helper workflows guide**

Explain:
- use `buildCSVImportScreenState(...)` for import-review UI state
- use `diagnoseCSVImport(...)` for developer debugging and import triage

- [ ] **Step 3: Update package usage guide**

Add diagnostics to the app-side CSV section with a minimal example and clear purpose

- [ ] **Step 4: Update API reference**

Document:
- `BKAppFacade.diagnoseCSVImport(...)`
- all new public diagnostics models

- [ ] **Step 5: Verify docs references**

Run:

```bash
rg -n "diagnoseCSVImport|BKAppCSVImportDiagnosticsReport|buildCSVImportScreenState" README.md docs
```

Expected:
- diagnostics helper appears in app-facing docs
- docs distinguish diagnostics from import-review state

## Task 5: Full Verification

**Files:**
- No source files; record verification outcomes after execution

- [ ] **Step 1: Run the focused facade tests**

Run:

```bash
swift test --filter BacktestingKitAppFacadeTests
```

Expected:
- PASS

- [ ] **Step 2: Run the full package tests**

Run:

```bash
swift test
```

Expected:
- PASS

- [ ] **Step 3: Run the docs scan**

Run:

```bash
rg -n "diagnoseCSVImport|BKAppCSVImportDiagnosticsReport|BKAppCSVImportStageDecision" README.md docs BacktestingKit/BacktestingKit.docc
```

Expected:
- new helper and model names are discoverable from package docs

- [ ] **Step 4: Update the todo review section**

Record:
- implementation files changed
- verification commands run
- outcome and any residual limitations

## Acceptance Criteria

- `BKAppFacade.diagnoseCSVImport(...)` exists as a public additive API
- diagnostics report captures inspection, inference, stage decisions, failure stage, bounded row failures, and compact summaries
- existing CSV import helpers keep their current behavior
- focused app-facade tests pass
- full `swift test` passes
- docs explain when to use diagnostics vs import-review state
