# Auto CSV Inference Facade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a safe, explicit CSV auto-inference layer to `BKAppFacade` that can detect settings, preview/validate/normalize/import with auto-applied settings, and preserve all current manual helper behavior.

**Architecture:** Extend the existing app-facing CSV import surface rather than creating a second parsing stack. The new inference helpers should detect `columnMapping`, `dateFormat`, and `reverse` conservatively, then delegate to the current manual `BKAppFacade` methods using effective settings so behavior stays inspectable and additive.

**Tech Stack:** Swift, XCTest, existing BacktestingKit parsing/validation/export helpers, repo-local Markdown docs

---

## File Structure

### Core implementation files

- Modify: `BacktestingKit/App/BKAppImportModels.swift`
  - Extend the app-facing import model family with inference and auto-wrapper result models.
- Modify: `BacktestingKit/App/BKAppFacade.swift`
  - Add the public auto-inference methods and private inference helpers.

### Tests

- Modify: `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`
  - Add focused tests for inference success, ambiguity, fallback, and auto-helper delegation.

### Documentation

- Modify: `README.md`
  - Add the new auto-inference entrypoints to the top-level app-facing path.
- Modify: `docs/ONBOARDING.md`
  - Route beginner CSV import flows toward the auto path first.
- Modify: `docs/GETTING_STARTED.md`
  - Add the auto helper family to the fast-start surface.
- Modify: `docs/HELPER_WORKFLOWS.md`
  - Document the inference -> auto preview -> auto validate -> auto run sequence.
- Modify: `docs/PACKAGE_USAGE_GUIDE.md`
  - Position the auto path as the easiest app-side import flow.
- Modify: `docs/API_REFERENCE.md`
  - Add the new public methods and inference models.
- Modify: `tasks/todo.md`
  - Track execution and verification for this pass.

### Reference files to consult while implementing

- `BacktestingKit/Data/BKCSVParsingSupport.swift`
- `BacktestingKit/Tools/BKValidationTool.swift`
- `BacktestingKit/Engine/BKQuickDemo.swift`

These should be reused, not bypassed.

---

### Task 1: Add Tracking For The Auto-Inference Pass

**Files:**
- Modify: `tasks/todo.md`

- [ ] **Step 1: Add a new task section**

Add a checklist section named `## 2026-04-09 - Auto CSV Inference Facade Implementation` with execution items for models, facade logic, tests, docs, and verification.

- [ ] **Step 2: Confirm the task section is present**

Run: `rg -n "Auto CSV Inference Facade Implementation" tasks/todo.md`
Expected: one match in the new section header

- [ ] **Step 3: Commit**

```bash
git add tasks/todo.md
git commit -m "chore: track auto csv inference facade work"
```

---

### Task 2: Add Inference And Auto-Wrapper Models

**Files:**
- Modify: `BacktestingKit/App/BKAppImportModels.swift`
- Test: `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`

- [ ] **Step 1: Write the failing model-shape tests**

Add tests that instantiate and inspect:

- `BKAppCSVInferenceIssue`
- `BKAppCSVInferredSettings`
- `BKAppCSVEffectiveSettings`
- `BKAppCSVInferenceReport`
- `BKAppCSVAutoPreviewReport`
- `BKAppCSVAutoValidationReport`
- `BKAppCSVAutoNormalizedReport`
- `BKAppCSVAutoRunReport`
- `BKAppCSVAutoMarkdownReport`

The tests should verify the new wrappers preserve:

- the nested manual report
- the inference report
- effective settings visibility

- [ ] **Step 2: Run the targeted test to verify it fails**

Run: `swift test --filter BacktestingKitAppFacadeTests`
Expected: FAIL with missing inference model types

- [ ] **Step 3: Add the model definitions**

Extend `BacktestingKit/App/BKAppImportModels.swift` with:

- a stable inference issue model
- optional inferred settings model
- concrete effective settings model
- inference report model
- one wrapper report per auto helper

Design rules:

- use existing import report models instead of duplicating payload shape
- keep models app-facing and focused
- make conformance choices match the nested payloads instead of forcing `Codable` where nested types do not support it

- [ ] **Step 4: Run the targeted test to verify the model layer passes**

Run: `swift test --filter BacktestingKitAppFacadeTests`
Expected: model-related test failures are gone, or the remaining failures have moved to missing facade methods

- [ ] **Step 5: Commit**

```bash
git add BacktestingKit/App/BKAppImportModels.swift Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift
git commit -m "feat: add app csv inference models"
```

---

### Task 3: Implement Safe CSV Inference

**Files:**
- Modify: `BacktestingKit/App/BKAppFacade.swift`
- Test: `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`
- Reference: `BacktestingKit/Data/BKCSVParsingSupport.swift`
- Reference: `BacktestingKit/Engine/BKQuickDemo.swift`

- [ ] **Step 1: Write the failing inference tests**

Add tests for:

- standard OHLCV header inference
- safe alias inference
- ambiguity detection when multiple headers could map to one field
- date-format inference for supported formats
- reverse-order inference for ascending and descending data
- partial inference with fallback

Each test should assert both:

- `inferredSettings`
- `effectiveSettings`

- [ ] **Step 2: Run the targeted test to verify it fails**

Run: `swift test --filter BacktestingKitAppFacadeTests`
Expected: FAIL with missing `detectCSVImportSettings(...)`

- [ ] **Step 3: Implement `detectCSVImportSettings(...)`**

Add the public method:

- `detectCSVImportSettings(symbol:csv:) -> BKAppCSVInferenceReport`

Add private helpers in `BKAppFacade.swift` for:

- safe header normalization
- safe alias matching
- required-field uniqueness checks
- bounded date-column sampling
- supported date-format trial
- bounded chronological-direction detection
- effective-settings resolution

Implementation rules:

- inspect headers only for mapping
- infer only when matches are unique and safe
- use a fixed supported date-format allowlist
- infer `reverse` only when date ordering is strictly monotonic
- record ambiguity and fallback as inference issues

- [ ] **Step 4: Run the targeted test to verify inference passes**

Run: `swift test --filter BacktestingKitAppFacadeTests`
Expected: inference-focused tests pass, remaining failures move to missing auto-wrapper methods

- [ ] **Step 5: Commit**

```bash
git add BacktestingKit/App/BKAppFacade.swift Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift
git commit -m "feat: infer csv import settings for app facade"
```

---

### Task 4: Implement Auto Preview, Validation, And Normalization

**Files:**
- Modify: `BacktestingKit/App/BKAppFacade.swift`
- Test: `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`

- [ ] **Step 1: Write the failing auto-helper tests**

Add tests for:

- `previewCSVAuto(...)`
- `validateCSVImportAuto(...)`
- `normalizeCSVImportAuto(...)`

The tests should verify:

- the inference report is attached
- manual helper output is preserved inside the wrapper
- effective settings are used when inference succeeds
- defaults are used when inference is incomplete

- [ ] **Step 2: Run the targeted test to verify it fails**

Run: `swift test --filter BacktestingKitAppFacadeTests`
Expected: FAIL with missing auto preview/validation/normalization methods

- [ ] **Step 3: Implement the auto helpers**

Add public methods:

- `previewCSVAuto(symbol:csv:maxRows:)`
- `validateCSVImportAuto(symbol:csv:)`
- `normalizeCSVImportAuto(symbol:csv:)`

Each method should:

1. call `detectCSVImportSettings(...)`
2. derive effective settings
3. delegate to the corresponding manual helper
4. wrap the result with the inference report

- [ ] **Step 4: Run the targeted test to verify the helpers pass**

Run: `swift test --filter BacktestingKitAppFacadeTests`
Expected: auto preview/validation/normalization tests pass

- [ ] **Step 5: Commit**

```bash
git add BacktestingKit/App/BKAppFacade.swift Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift
git commit -m "feat: add auto csv preview validation and normalization"
```

---

### Task 5: Implement Auto Execution And Markdown Export

**Files:**
- Modify: `BacktestingKit/App/BKAppFacade.swift`
- Test: `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`

- [ ] **Step 1: Write the failing execution tests**

Add tests for:

- `runCSVImportAuto(...)` success
- `runCSVImportAuto(...)` fallback-based success
- `runCSVImportAuto(...)` structured failure
- `runCSVImportAutoAndExportMarkdown(...)` success

The tests should verify:

- the nested manual run report is preserved
- inference/effective settings are visible
- Markdown export still uses the current export path

- [ ] **Step 2: Run the targeted test to verify it fails**

Run: `swift test --filter BacktestingKitAppFacadeTests`
Expected: FAIL with missing auto execution methods

- [ ] **Step 3: Implement the execution helpers**

Add public methods:

- `runCSVImportAuto(symbol:csv:preset:log:)`
- `runCSVImportAutoAndExportMarkdown(symbol:csv:preset:title:log:)`

Each method should:

1. call `detectCSVImportSettings(...)`
2. resolve effective settings
3. delegate to the existing manual run helper
4. return the wrapper report with inference context

- [ ] **Step 4: Run the targeted test to verify execution passes**

Run: `swift test --filter BacktestingKitAppFacadeTests`
Expected: all app-facade tests pass

- [ ] **Step 5: Commit**

```bash
git add BacktestingKit/App/BKAppFacade.swift Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift
git commit -m "feat: add auto csv import execution helpers"
```

---

### Task 6: Document The Auto CSV Path

**Files:**
- Modify: `README.md`
- Modify: `docs/ONBOARDING.md`
- Modify: `docs/GETTING_STARTED.md`
- Modify: `docs/HELPER_WORKFLOWS.md`
- Modify: `docs/PACKAGE_USAGE_GUIDE.md`
- Modify: `docs/API_REFERENCE.md`

- [ ] **Step 1: Add README discovery copy**

Document the new auto path in the top-level app-facing surface:

- `detectCSVImportSettings(...)`
- `previewCSVAuto(...)`
- `validateCSVImportAuto(...)`
- `normalizeCSVImportAuto(...)`
- `runCSVImportAuto(...)`

- [ ] **Step 2: Update onboarding**

Adjust the beginner CSV import section so the recommendation order is:

1. auto detect
2. auto preview
3. auto validate
4. auto run
5. fall back to manual override when needed

- [ ] **Step 3: Update getting-started and helper workflows**

Document the inference -> auto-preview -> auto-validate -> auto-run flow and show one short example.

- [ ] **Step 4: Update package guide and API reference**

Add:

- auto-inference methods
- inference report models
- explanation that the manual path remains available and unchanged

- [ ] **Step 5: Run the docs discoverability scan**

Run:

```bash
rg -n "detectCSVImportSettings|previewCSVAuto|validateCSVImportAuto|normalizeCSVImportAuto|runCSVImportAuto|runCSVImportAutoAndExportMarkdown" README.md docs BacktestingKit/BacktestingKit.docc
```

Expected: the new auto helper family appears across the public docs

- [ ] **Step 6: Commit**

```bash
git add README.md docs/ONBOARDING.md docs/GETTING_STARTED.md docs/HELPER_WORKFLOWS.md docs/PACKAGE_USAGE_GUIDE.md docs/API_REFERENCE.md
git commit -m "docs: add auto csv inference facade guides"
```

---

### Task 7: Final Verification And Task Closure

**Files:**
- Modify: `tasks/todo.md`
- Test: `Tests/BacktestingKitTests/BacktestingKitAppFacadeTests.swift`

- [ ] **Step 1: Run targeted verification**

Run: `swift test --filter BacktestingKitAppFacadeTests`
Expected: PASS

- [ ] **Step 2: Run full verification**

Run: `swift test`
Expected: PASS

- [ ] **Step 3: Update the task checklist and review notes**

Mark the implementation checklist complete and add a short review entry covering:

- files added/modified
- new auto helper family
- verification commands
- whether any non-goals were intentionally preserved

- [ ] **Step 4: Commit**

```bash
git add tasks/todo.md
git commit -m "chore: close auto csv inference facade task"
```

---

## Notes For The Implementer

- Do not mutate the semantics of the current manual `BKAppFacade` CSV helper family.
- Do not add implicit inference to existing methods.
- Prefer small private helpers in `BKAppFacade.swift` over introducing a new parsing subsystem.
- Keep inference deterministic and conservative; ambiguity should surface in reports, not be hidden.
- Reuse the existing parser and current app-facing manual report types whenever possible.
