# Auto CSV Inference Facade Design

Date: 2026-04-09

## Goal

Make app-side CSV import easier by adding a safe, explicit inference layer on top of the current `BKAppFacade` CSV import helpers.

This pass should:

- reduce app boilerplate for CSV import screens
- infer only safe structural defaults
- provide an auto-apply path for preview, validation, normalization, and execution
- preserve all existing manual helper behavior
- avoid breaking changes

This pass should not:

- change the semantics of existing `BKAppFacade` CSV helpers
- introduce hidden inference into existing manual methods
- guess delimiters
- perform speculative or lossy schema inference
- reach into manager-only workflows

## Current State

The package already exposes an app-facing CSV import family on `BKAppFacade`:

- `inspectCSV(...)`
- `previewCSV(...)`
- `validateCSVImport(...)`
- `normalizeCSVImport(...)`
- `runCSVImport(...)`
- `runCSVImportAndExportMarkdown(...)`

These helpers removed a large amount of parsing and execution orchestration from app code, but callers still need to know or manually choose:

- `columnMapping`
- `dateFormat`
- `reverse`

For beginner app integration and upload/import UIs, that still leaves avoidable decision-making in the host app.

## Design Summary

Add a second, explicit CSV auto-inference layer to `BKAppFacade`.

The new helpers will:

- infer safe settings from CSV structure and bounded data samples
- expose both inferred and effective settings
- delegate to the current manual helpers after settings resolution
- keep inference inspectable rather than hidden

The current manual helper family remains unchanged and continues to be the exact-control path.

## Recommended Approach

Use a dual-surface approach:

- keep the current manual helper APIs intact
- add explicit inference-plus-auto-apply helpers beside them

This is better than silently inferring inside the current methods because:

- it avoids behavior drift for existing callers
- it keeps debugging straightforward
- it makes uncertainty visible in app UIs
- it lets apps upgrade incrementally from manual to auto flows

## Public API

New additive APIs on `BKAppFacade`:

- `detectCSVImportSettings(symbol:csv:) -> BKAppCSVInferenceReport`
- `previewCSVAuto(symbol:csv:maxRows:) -> BKAppCSVAutoPreviewReport`
- `validateCSVImportAuto(symbol:csv:) -> BKAppCSVAutoValidationReport`
- `normalizeCSVImportAuto(symbol:csv:) -> BKAppCSVAutoNormalizedReport`
- `runCSVImportAuto(symbol:csv:preset:log:) -> BKAppCSVAutoRunReport`
- `runCSVImportAutoAndExportMarkdown(symbol:csv:preset:title:log:) -> BKAppCSVAutoMarkdownReport`

Existing APIs that remain unchanged:

- `inspectCSV(symbol:csv:columnMapping:)`
- `previewCSV(symbol:csv:dateFormat:reverse:columnMapping:maxRows:)`
- `validateCSVImport(symbol:csv:dateFormat:reverse:columnMapping:)`
- `normalizeCSVImport(symbol:csv:dateFormat:reverse:columnMapping:)`
- `runCSVImport(symbol:csv:preset:dateFormat:reverse:columnMapping:log:)`
- `runCSVImportAndExportMarkdown(...)`

## Inference Scope

Inference is intentionally conservative.

The system may infer:

- `columnMapping`
- `dateFormat`
- `reverse`

The system will not infer:

- delimiter variants
- malformed header recovery
- fuzzy or weak alias matches that are not clearly safe
- derived prices or synthesized fields

## Inference Rules

### 1. Column Mapping

Column mapping inference should:

- inspect the header row only
- compare headers against a small allowlist of safe aliases
- support required fields:
  - `date`
  - `open`
  - `high`
  - `low`
  - `close`
  - `volume`
- optionally support `adjustedClose`
- infer a mapping only when every required field is uniquely resolved
- reject ambiguous matches

If mapping cannot be safely inferred, the report should:

- return no inferred mapping
- record the unresolved or ambiguous fields
- fall back to the parser defaults for the auto path

### 2. Date Format

Date format inference should:

- inspect a bounded sample from the chosen date column
- try a fixed ordered list of supported formats already compatible with the parser
- succeed only when exactly one candidate format works consistently across the sample
- record ambiguity when multiple formats match
- record failure when no supported format matches

### 3. Reverse Order

Reverse-order inference should:

- use the chosen date column and effective date format
- parse a bounded sample of dates
- infer `reverse = true` when dates are strictly descending
- infer `reverse = false` when dates are strictly ascending
- return no inferred value when mixed, ambiguous, or unparseable

## Effective Settings

Each auto helper should return both:

- the inferred settings
- the effective settings actually used

Effective settings are resolved as:

- use inferred values when available
- otherwise fall back to the same defaults used by the current manual helper family

This preserves determinism while making the applied behavior visible to the caller.

## Models

Additive app-facing models:

- `BKAppCSVInferenceIssue`
- `BKAppCSVInferredSettings`
- `BKAppCSVEffectiveSettings`
- `BKAppCSVInferenceReport`
- `BKAppCSVAutoPreviewReport`
- `BKAppCSVAutoValidationReport`
- `BKAppCSVAutoNormalizedReport`
- `BKAppCSVAutoRunReport`
- `BKAppCSVAutoMarkdownReport`

### Model Responsibilities

`BKAppCSVInferenceIssue`

- stable, user-displayable note about success, fallback, or ambiguity
- should include:
  - code
  - message
  - severity
  - optional metadata

`BKAppCSVInferredSettings`

- optional inferred values for:
  - `columnMapping`
  - `dateFormat`
  - `reverse`

`BKAppCSVEffectiveSettings`

- concrete settings actually used by auto helpers

`BKAppCSVInferenceReport`

- includes:
  - `inspection`
  - `inferredSettings`
  - `effectiveSettings`
  - `issues`
  - `isFullyInferred`

Each auto report model should wrap:

- the `BKAppCSVInferenceReport`
- the corresponding existing manual report

This avoids duplicating existing output structures and keeps the layering thin.

## Internal Architecture

Implementation should be thin and additive.

Recommended internal shape:

- add inference models in `BacktestingKit/App/`
- add a small private inference helper inside `BKAppFacade.swift` or a nearby app-facing helper file
- reuse the current manual `BKAppFacade` helper family after settings resolution

Internal flow:

1. `detectCSVImportSettings(...)`
   - run structural inspection
   - infer mapping
   - infer date format
   - infer reverse
   - produce the inference report

2. `previewCSVAuto(...)`
   - call `detectCSVImportSettings(...)`
   - call `previewCSV(...)` with effective settings

3. `validateCSVImportAuto(...)`
   - same pattern

4. `normalizeCSVImportAuto(...)`
   - same pattern

5. `runCSVImportAuto(...)`
   - same pattern

6. `runCSVImportAutoAndExportMarkdown(...)`
   - same pattern

No second parsing stack should be introduced.

## Error Handling

The auto helpers should not hide uncertainty.

Rules:

- if inference is ambiguous, record that explicitly
- if auto helpers fall back to defaults, record that explicitly
- if parsing fails after fallback, the resulting report should include both:
  - the inference report
  - the existing validation/normalization/run failure details

This ensures app UIs can distinguish between:

- successful inference
- fallback-based execution
- post-inference parse failure

## Documentation Impact

Update:

- `README.md`
- `docs/ONBOARDING.md`
- `docs/GETTING_STARTED.md`
- `docs/HELPER_WORKFLOWS.md`
- `docs/PACKAGE_USAGE_GUIDE.md`
- `docs/API_REFERENCE.md`

Docs should position the new surface as:

- the easiest app-side import path
- especially useful for onboarding/import screens
- explicit auto-apply, not hidden magic

## Verification Plan

Targeted verification:

- inference success for standard OHLCV headers
- inference success for safe aliases
- ambiguity reporting for conflicting headers
- date format inference success for supported formats
- reverse inference success for ascending and descending data
- fallback behavior when inference is incomplete
- auto preview/validation/normalization/run correctness
- parity between manual and auto helpers when inferred settings match explicit settings

Required commands:

- `swift test --filter BacktestingKitAppFacadeTests`
- `swift test`
- `rg -n "detectCSVImportSettings|previewCSVAuto|validateCSVImportAuto|normalizeCSVImportAuto|runCSVImportAuto|runCSVImportAutoAndExportMarkdown" README.md docs BacktestingKit/BacktestingKit.docc`

## Acceptance Criteria

This pass is complete when:

- `BKAppFacade` exposes a coherent CSV auto-inference helper family
- current manual CSV import helpers remain unchanged
- auto helpers always surface inferred and effective settings
- safe-only inference rules are documented and tested
- docs clearly route beginner/app integrations toward the new auto path
- focused and full test suites pass

## Non-Goals

This pass does not include:

- delimiter detection
- file-path or `Data` inputs
- manager-facing ingestion helpers
- automatic mutation of existing manual APIs
- heuristic guessing that cannot be explained deterministically
