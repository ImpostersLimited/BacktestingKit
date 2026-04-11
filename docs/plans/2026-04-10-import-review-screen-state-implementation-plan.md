# Import Review Screen State Implementation Plan

> **Goal:** Add one app-facing import-review helper that assembles inspection, safe inference, preview, validation, normalization readiness, grouped issues, and a stable UI status for CSV import screens before execution.

## Scope

This pass remains strictly additive and import-review only.

It includes:

- `BKAppFacade.buildCSVImportScreenState(symbol:csv:maxRows:)`
- app-facing presentation models for grouped issues and screen status
- focused XCTest coverage for ready / needs-review / invalid states
- one dedicated CSV import tutorial
- one `CHOOSE_YOUR_SURFACE.md` guide
- app-integration/tutorial/doc refreshes that make the CSV review flow the canonical beginner app path

It does not include:

- new execution helpers
- preset recommendation logic
- file-path import helpers
- changes to the semantics of existing CSV helper methods

## Implementation Strategy

Build the new helper as a pure composition layer over the current CSV import facade:

1. `inspectCSV(...)`
2. `detectCSVImportSettings(...)`
3. `previewCSVAuto(...)`
4. `validateCSVImportAuto(...)`
5. `normalizeCSVImportAuto(...)` when validation is ready enough

The screen-state helper should not duplicate parsing or validation logic. It should convert existing report payloads into one app-facing review model and one presentation-oriented issue grouping.

## Files

### Core implementation

- Modify: `BacktestingKit/App/BKAppImportModels.swift`
- Modify: `BacktestingKit/App/BKAppFacade.swift`

### Tests

- Modify: `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`

### Documentation

- Modify: `README.md`
- Modify: `docs/ONBOARDING.md`
- Modify: `docs/GETTING_STARTED.md`
- Modify: `docs/HELPER_WORKFLOWS.md`
- Modify: `docs/PACKAGE_USAGE_GUIDE.md`
- Modify: `docs/API_REFERENCE.md`
- Add: `docs/CHOOSE_YOUR_SURFACE.md`
- Modify: `BacktestingKit/BacktestingKit.docc/BacktestingKit.md`
- Modify: `BacktestingKit/BacktestingKit.docc/BKAppIntegrationTutorial.tutorial`
- Add: `BacktestingKit/BacktestingKit.docc/BKCSVImportTutorial.tutorial`
- Modify: `BacktestingKit/BacktestingKit.docc/BacktestingKitTutorials.tutorial`

## Tasks

### 1. Add tracking and implementation artifact

- [ ] Confirm the new implementation section is present in `tasks/todo.md`
- [ ] Keep this plan file updated as the execution artifact for the pass

### 2. Add app-facing import-review models

- [ ] Extend `BKAppImportModels.swift` with:
  - `BKAppCSVImportScreenState`
  - `BKAppCSVImportScreenStatus`
  - `BKAppCSVImportIssueSection`
  - `BKAppCSVImportIssueItem`
  - `BKAppCSVImportIssueSource`
- [ ] Use existing nested report models directly rather than copying preview/validation/normalization fields
- [ ] Reuse `BKValidationSeverity` for severity to stay aligned with the package’s current validation vocabulary unless a small bridging enum is clearly justified

### 3. Implement `buildCSVImportScreenState(...)`

- [ ] Add `BKAppFacade.buildCSVImportScreenState(symbol:csv:maxRows:)`
- [ ] Always run inspection first
- [ ] Always run inference after inspection
- [ ] Build preview when structural inspection and/or inference leave the CSV previewable
- [ ] Build validation when preview/preparation is viable
- [ ] Build normalization only when validation indicates the CSV is ready enough
- [ ] Group issues into presentation sections:
  - Inspection
  - Inference
  - Validation
- [ ] Compute:
  - `status = .ready`
  - `status = .needsReview`
  - `status = .invalid`
- [ ] Compute `isReadyToContinue` only when the state can safely hand off to execution helpers

### 4. Add focused tests

- [ ] Add a ready-state test for a clean standard CSV
- [ ] Add a needs-review test for a CSV that is usable but inference-ambiguous or fallback-driven
- [ ] Add an invalid-state test for empty or decisively invalid CSV
- [ ] Add assertions for:
  - grouped issue sections
  - readiness flag
  - optional preview/validation/normalization population
  - status computation

### 5. Refresh docs and tutorials

- [ ] Add `docs/CHOOSE_YOUR_SURFACE.md` explaining:
  - `BKAppFacade`
  - `BKEngine`
  - `BacktestingKitManager`
  - tool helpers
- [ ] Add a dedicated CSV import tutorial in DocC
- [ ] Update the app integration tutorial to start with `BKAppFacade` import-review and then explain when to drop to `BKEngine`
- [ ] Cross-link the new guide/tutorial from README, onboarding, getting started, helper workflows, package usage guide, API reference, and the DocC tutorial index

### 6. Verify

- [ ] Run focused app-facade tests
- [ ] Run full `swift test`
- [ ] Run a docs discoverability scan for the new helper/tutorial/guide
- [ ] Update the review notes in `tasks/todo.md`

## Verification Commands

```bash
swift test --filter BacktestingKitAppFacadeTests
swift test
rg -n "buildCSVImportScreenState|BKCSVImportTutorial|CHOOSE_YOUR_SURFACE" README.md docs BacktestingKit/BacktestingKit.docc
```

## Acceptance Criteria

- The package exposes `BKAppFacade.buildCSVImportScreenState(...)`
- The helper remains import-review only and does not trigger execution
- Apps receive one stable screen-state payload with grouped issues and readiness
- Existing CSV helper semantics remain unchanged
- The CSV import review flow is discoverable from README, onboarding docs, and DocC
- Focused and full verification pass
