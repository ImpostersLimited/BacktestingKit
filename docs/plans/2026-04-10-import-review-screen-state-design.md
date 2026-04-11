# Import Review Screen State Design

## Goal

Add one app-facing helper that prepares the full CSV import review state for UI flows before execution:

- inspection
- safe inference
- preview
- validation
- normalization summary
- grouped user-displayable issues
- one simple readiness/status decision

This pass is explicitly import-review only. It must not trigger execution, choose a strategy preset, export reports, or expand into a second app facade.

## Why This Exists

The package already provides strong app-facing CSV primitives on `BKAppFacade`:

- `inspectCSV(...)`
- `detectCSVImportSettings(...)`
- `previewCSVAuto(...)`
- `validateCSVImportAuto(...)`
- `normalizeCSVImportAuto(...)`
- `runCSVImport(...)`
- `runCSVImportAuto(...)`

Those helpers are individually useful, but a real import screen still has to orchestrate them and decide:

- what to show first
- what counts as warning vs failure
- whether preview/validation/normalization should be attempted
- how to present grouped issues
- whether the UI can enable the next step

That orchestration belongs in the package because it is stable, repeatable, and app-facing.

## Non-Goals

This pass must not:

- change any existing helper semantics
- add implicit execution behavior
- recommend or choose strategy presets
- add file-based import helpers
- add a second facade namespace
- replace `runCSVImport(...)` or `runCSVImportAuto(...)`

## Recommended Approach

Use a hybrid usability pass:

1. Add one new helper on `BKAppFacade` for import-review state assembly.
2. Add a small result-model layer that is explicitly presentation-shaped.
3. Update tutorials and docs so the package advertises the CSV import review flow as the canonical app-side path.

This gives app teams a practical UI integration surface without bloating the runtime API.

## Public API

Add one new helper:

```swift
public enum BKAppFacade {
    public static func buildCSVImportScreenState(
        symbol: String,
        csv: String,
        maxRows: Int = 5
    ) -> BKAppCSVImportScreenState
}
```

### Intent

This helper is the single entrypoint for app import-review screens.

It should:

- inspect the CSV
- infer safe settings when possible
- build a preview when possible
- validate with the inferred settings
- normalize when the CSV is ready enough
- group issues into app-friendly sections
- compute one stable UI status and readiness flag

It should not:

- run a backtest
- export results
- mutate existing helper behavior

## Result Models

```swift
public struct BKAppCSVImportScreenState: Equatable, Sendable {
    public let symbol: String
    public let inspection: BKAppCSVInspectionReport
    public let inference: BKAppCSVInferenceReport
    public let preview: BKAppCSVAutoPreviewReport?
    public let validation: BKAppCSVAutoValidationReport?
    public let normalization: BKAppCSVAutoNormalizedReport?
    public let issues: [BKAppCSVImportIssueSection]
    public let status: BKAppCSVImportScreenStatus
    public let isReadyToContinue: Bool
}
```

Supporting types:

```swift
public enum BKAppCSVImportScreenStatus: String, Codable, Equatable, Sendable {
    case ready
    case needsReview
    case invalid
}

public struct BKAppCSVImportIssueSection: Codable, Equatable, Sendable {
    public let title: String
    public let items: [BKAppCSVImportIssueItem]
}

public struct BKAppCSVImportIssueItem: Codable, Equatable, Sendable {
    public let severity: BKPresentationSeverity
    public let code: String
    public let message: String
    public let source: BKAppCSVImportIssueSource
}

public enum BKAppCSVImportIssueSource: String, Codable, Equatable, Sendable {
    case inspection
    case inference
    case validation
}
```

### Modeling Principles

- Preserve the underlying detailed reports for advanced callers.
- Add one presentation-shaped layer for direct UI rendering.
- Give apps both a high-level status and a concrete grouped issue list.
- Keep the models additive and app-facing.

## Internal Flow

`buildCSVImportScreenState(...)` should compose the existing helper family in this order:

1. `inspectCSV(...)`
2. `detectCSVImportSettings(...)`
3. `previewCSVAuto(...)`
4. `validateCSVImportAuto(...)`
5. `normalizeCSVImportAuto(...)` when safe to do so

### Control Flow Rules

- Always run `inspectCSV(...)` first.
- Always run `detectCSVImportSettings(...)` after inspection.
- Build `preview` when the CSV is structurally parseable enough to preview.
- Build `validation` when preview/preparation is viable.
- Build `normalization` only when validation indicates the CSV is ready enough to normalize safely.
- If a later step cannot run, return `nil` for that sub-report and surface the reason through grouped issues.

## Issue Grouping Rules

The helper should produce grouped issue sections by source:

- `Inspection`
- `Inference`
- `Validation`

### Mapping Rules

- Inspection issues come from `inspection.preflight.validation.issues`
- Inference issues come from `inference.issues`
- Validation issues come from `validation.validation.issues` when validation exists

Each grouped item should flatten into:

- severity
- code
- message
- source

This keeps the models UI-friendly while preserving source traceability.

## Status Rules

### `ready`

Use when:

- validation exists
- validation is ready
- normalization exists

### `needsReview`

Use when:

- the CSV is not definitively invalid
- but there are warnings, ambiguities, or fallback conditions that a user should review

Examples:

- inference ambiguity
- fallback/default settings used
- preview available but validation not fully ready

### `invalid`

Use when:

- inspection decisively fails, or
- validation decisively fails

### `isReadyToContinue`

Set `true` only when the screen can safely hand off into:

- `runCSVImport(...)`, or
- `runCSVImportAuto(...)`

This should generally align with `status == .ready`.

## Example Usage

```swift
let state = BKAppFacade.buildCSVImportScreenState(
    symbol: "AAPL",
    csv: csv,
    maxRows: 5
)

switch state.status {
case .ready:
    nextButton.isEnabled = true
case .needsReview:
    nextButton.isEnabled = false
case .invalid:
    nextButton.isEnabled = false
}

for section in state.issues {
    print(section.title)
    for item in section.items {
        print(item.code, item.message)
    }
}
```

## Documentation Plan

This pass should also improve discoverability.

### Add

- a dedicated CSV import tutorial in DocC
- `docs/CHOOSE_YOUR_SURFACE.md`

### Refresh

- `README.md`
- `docs/ONBOARDING.md`
- `docs/GETTING_STARTED.md`
- `docs/HELPER_WORKFLOWS.md`
- `docs/PACKAGE_USAGE_GUIDE.md`
- `docs/API_REFERENCE.md`
- `BacktestingKit/BacktestingKit.docc/BKAppIntegrationTutorial.tutorial`

### Messaging Changes

- The app integration story should start with `BKAppFacade`.
- `BKEngine` should be presented as the canonical lower-level execution surface after the facade path.
- The CSV import tutorial should be framed as the real app path for pasted/uploaded/imported user CSV.

## Testing Plan

Add focused XCTest coverage for:

- ready state with clean CSV
- needs-review state with inference ambiguity
- invalid state with failed inspection or failed validation
- grouped issue section construction
- normalization omission when validation is not ready
- `isReadyToContinue` consistency with the computed status

Also keep:

- the existing manual helper tests unchanged
- the existing auto helper semantics unchanged

## Acceptance Criteria

- `BKAppFacade` exposes `buildCSVImportScreenState(...)`
- the result model is app-facing and directly useful for import-review UI
- the helper is deterministic and additive
- existing CSV helper semantics do not change
- docs clearly present the facade-first app path
- a dedicated CSV import tutorial exists
- focused tests and full `swift test` pass

## Risks

### Over-modeling the presentation layer

If too many UI concepts are pushed into the public model, the package becomes opinionated in the wrong way.

Mitigation:

- keep only grouped issue sections, status, and readiness
- do not add execution CTA concepts, button labels, or view-specific state

### Hidden duplication

If the helper reimplements CSV logic instead of composing existing helpers, behavior drift will appear.

Mitigation:

- build on top of current facade helpers only
- keep new logic limited to sequencing, issue grouping, and status computation

### Tutorial drift

The app integration tutorial currently starts too low in the stack.

Mitigation:

- update the tutorial in the same pass as the helper
- explicitly reposition `BKEngine` as the next step after facade-based app onboarding

## Recommendation

Implement this as one additive hybrid usability pass:

- one helper
- one small presentation model layer
- one CSV import tutorial
- one guide for choosing the right public surface
- one refresh of app integration discovery

That is the highest-value next step for app-side package usability.
