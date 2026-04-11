# CSV Import Diagnostics Design

Date: 2026-04-10
Status: Approved for spec review by user conversation
Scope: Add one developer-facing diagnostics helper for app-side CSV import flows without changing any existing API behavior

## Goal

Add a single app-facing diagnostics entrypoint that helps developers understand why a CSV import failed or looks suspicious.

The helper should answer:

- what did the package think the CSV looked like?
- what settings did it infer?
- what settings did it actually use?
- which import stage failed or degraded?
- which rows are representative examples of the failure?

This pass is intentionally:

- additive only
- developer-facing only
- independent from the import-review screen-state flow
- in-memory only, with no export helpers

## Non-Goals

This pass does not:

- add user-shareable support bundles
- add markdown/text export for diagnostics
- change `buildCSVImportScreenState(...)`
- change the behavior of existing manual or auto CSV import helpers
- add preset execution or app UI state on top of diagnostics
- introduce a second diagnostics namespace outside `BKAppFacade`

## Recommended Approach

Implement a single postmortem helper on `BKAppFacade`:

```swift
static func diagnoseCSVImport(
    symbol: String,
    csv: String,
    maxFailureRows: Int = 5
) -> BKAppCSVImportDiagnosticsReport
```

Why this approach:

- lowest API risk
- aligns with the current facade-first app integration story
- keeps diagnostics independent from import-review UI flows
- avoids fragmenting the app-facing API into multiple narrower diagnostics helpers
- leaves room for future splitting if repeated diagnostics subproblems emerge

Rejected alternatives:

1. Diagnostics helper family on `BKAppFacade`
   Too much surface area for an app-facing debugging need that can be solved with one stable report object.

2. Deep diagnostics types first, then a facade wrapper
   More reusable internally, but higher implementation cost and more likely to over-design a still-evolving app integration need.

## Public API

Add one helper to `BKAppFacade`:

```swift
public static func diagnoseCSVImport(
    symbol: String,
    csv: String,
    maxFailureRows: Int = 5
) -> BKAppCSVImportDiagnosticsReport
```

Intent:

- independent from `buildCSVImportScreenState(...)`
- independent from execution helpers like `runCSVImport(...)`
- developer-facing only
- no export sidecar
- no UI-specific readiness framing beyond viability

## Public Models

### `BKAppCSVImportDiagnosticsReport`

```swift
public struct BKAppCSVImportDiagnosticsReport: Equatable, Sendable {
    public let symbol: String
    public let inspection: BKAppCSVInspectionReport
    public let inference: BKAppCSVInferenceReport
    public let stageDecisions: [BKAppCSVImportStageDecision]
    public let failureStage: BKAppCSVImportFailureStage?
    public let rowFailures: [BKAppCSVRowFailureExample]
    public let previewSummary: BKAppCSVPreviewSummary?
    public let normalizationSummary: BKAppCSVNormalizationSummary?
    public let isImportViable: Bool
}
```

### `BKAppCSVImportStageDecision`

```swift
public struct BKAppCSVImportStageDecision: Equatable, Sendable {
    public let stage: BKAppCSVImportDiagnosticStage
    public let outcome: BKAppCSVImportStageOutcome
    public let message: String
}
```

### `BKAppCSVImportDiagnosticStage`

```swift
public enum BKAppCSVImportDiagnosticStage: String, Codable, Equatable, Sendable {
    case inspection
    case inference
    case preview
    case validation
    case normalization
}
```

### `BKAppCSVImportStageOutcome`

```swift
public enum BKAppCSVImportStageOutcome: String, Codable, Equatable, Sendable {
    case success
    case warning
    case failed
    case skipped
}
```

### `BKAppCSVImportFailureStage`

```swift
public enum BKAppCSVImportFailureStage: String, Codable, Equatable, Sendable {
    case inspection
    case inference
    case preview
    case validation
    case normalization
}
```

### `BKAppCSVRowFailureExample`

```swift
public struct BKAppCSVRowFailureExample: Equatable, Sendable {
    public let rowIndex: Int
    public let rawRow: String
    public let message: String
}
```

## Behavior Rules

The helper runs diagnostics in stage order and retains partial information even when later stages fail.

Stage order:

1. inspection
2. inference
3. preview
4. validation
5. normalization

### Stage execution policy

- `inspection` always runs
- `inference` always runs
- `preview` runs when the CSV is structurally parseable enough to attempt a preview
- `validation` runs when preview/configuration is viable enough to continue
- `normalization` runs only when validation indicates the rows can be safely normalized

For every stage:

- append exactly one `BKAppCSVImportStageDecision`
- use one of `success`, `warning`, `failed`, or `skipped`
- write the message as the most relevant decision or fallback at that stage

### Failure stage

`failureStage` should be:

- the first stage that decisively fails
- `nil` when no stage fails decisively

Warnings and fallbacks do not automatically set `failureStage`.

### Row-level failures

`rowFailures` should:

- capture up to `maxFailureRows`
- prefer concrete raw rows over abstract counts
- surface representative failures from preview, validation, or normalization
- remain empty when no concrete row-level failures are available

No fabricated failure rows should be produced.

### Summaries

`previewSummary` should exist only when preview succeeds enough to produce a meaningful summary.

It should remain compact and avoid returning the full preview rows. The summary should cover:

- previewed row count
- date range when available
- effective mapping/date-format/reverse used at preview time

`normalizationSummary` should exist only when normalization succeeds enough to produce meaningful normalized output.

It should cover:

- normalized row count
- first/last timestamp when available
- whether ordering was normalized

### Viability

`isImportViable` should be `true` only when:

- validation succeeds, and
- normalization succeeds enough to produce usable normalized output, or normalization is otherwise clearly sufficient for the downstream import path

This keeps the diagnostics helper informative without turning it into an execution helper.

## Internal Composition

The diagnostics helper should compose the existing app-facing CSV helpers rather than introducing a parallel parsing stack.

Expected internal flow:

1. call `inspectCSV(...)`
2. call `detectCSVImportSettings(...)`
3. attempt `previewCSVAuto(...)` when viable
4. attempt `validateCSVImportAuto(...)` when viable
5. attempt `normalizeCSVImportAuto(...)` when viable
6. build summaries, failure stage, and row failure examples

This keeps behavior aligned with the current facade APIs and reduces drift between review, auto-import, and diagnostics paths.

## Error Handling

The helper itself should not throw for ordinary CSV issues. Diagnostics should be returned as structured data whenever possible.

If an internal facade step throws unexpectedly:

- record a failed stage decision at the appropriate stage
- set `failureStage`
- preserve all previously collected diagnostics
- return an empty `rowFailures` array unless a concrete failing row is available

This preserves the helper's usefulness during debugging.

## Testing Strategy

Add focused XCTest coverage that proves:

1. successful CSV diagnostics
   - all expected stages recorded
   - no failure stage
   - viability true

2. inference ambiguity
   - inference decision downgraded to warning
   - effective settings still reported
   - helper continues when safe to do so

3. preview-stage failure with row examples
   - failure stage is preview
   - bounded row failure examples are returned

4. validation-stage failure with row examples
   - failure stage is validation
   - viability false

5. normalization-stage failure
   - preview/validation context retained
   - normalization summary absent

6. bounded `maxFailureRows`
   - output never exceeds the requested row-example limit

7. additive behavior
   - existing helpers retain their current behavior and signatures

## Documentation Impact

This pass should update only the app-facing docs that explain how developers debug CSV imports.

Recommended updates:

- `README.md`
- `docs/HELPER_WORKFLOWS.md`
- `docs/PACKAGE_USAGE_GUIDE.md`
- `docs/API_REFERENCE.md`

The docs should position this helper as:

- the developer-facing debugging entrypoint for CSV import issues
- distinct from `buildCSVImportScreenState(...)`, which exists for app import-review UI state

## Implementation Notes

- keep the new surface on `BKAppFacade`
- keep the report models under `BacktestingKit/App/`
- avoid introducing export/reporting helpers in this pass
- avoid coupling diagnostics to presets, execution, or support-ticket packaging

## Acceptance Criteria

This pass is complete when:

- `BKAppFacade.diagnoseCSVImport(...)` exists as a public additive API
- the diagnostics report captures decisions, inferred/effective settings, and bounded row-level failure examples
- the helper returns partial diagnostics when later stages fail
- focused XCTest coverage passes
- app-facing docs explain when to use diagnostics vs import-review state
