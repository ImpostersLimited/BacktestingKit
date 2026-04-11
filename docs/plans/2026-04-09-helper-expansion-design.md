# Helper Expansion Design

## Goal

Add a broader set of helper functions across the three existing public surfaces:

- `BKEngine` / `BKEngineOneLiner` for app-facing workflows
- `BacktestingKitManager` for reusable strategy/indicator/report composition
- `BK*Tool` utilities for validation, diagnostics, export, and demo operations

The expansion must remain strictly additive, avoid breaking existing public signatures, and improve the package first for:

- app developers integrating the package
- demo, docs, and smoke-test workflows

## Non-Goals

- No renames or removals of existing public APIs
- No behavioral changes to existing helper methods
- No refactor that changes core v2/v3 simulation contracts
- No large restructuring of the package layout
- No attempt to solve every advanced composition need in the first pass

## Current State

The project already exposes helpers, but they are fragmented:

- `BKEngine` and `BKEngineOneLiner` provide canonical execution entrypoints and one-liner request wrappers
- `BacktestingKitManager` exposes many direct indicator and strategy helpers, but mostly at a low or inconsistent abstraction level
- `BKQuickDemo` covers one narrow bundled SMA demo flow
- `BKValidationTool`, `BKExportTool`, `BKDiagnosticsTool`, `BKScenarioTool`, `BKBenchmarkTool`, and `BKParityTool` exist, but they are mostly point utilities rather than cohesive app-friendly workflows

This creates three usability gaps:

1. App integrations still need to compose several steps manually for common workflows
2. Demo/docs users have only a small number of canned smoke-test entrypoints
3. Lower-level manager helpers exist, but they do not consistently provide boilerplate reduction for common report-building and strategy setup tasks

## Design Principles

### 1. Stay additive

Every new helper should be implemented as:

- a new static function
- a new convenience overload
- a new additive namespace/type
- a new public result/report model

Existing call sites should remain valid without modification.

### 2. Keep the current surface hierarchy

- `BKEngine` remains the canonical top-level app integration API
- `BacktestingKitManager` remains the home for low-to-mid-level composition helpers
- `BK*Tool` remains the home for operational utilities

We should avoid introducing an entirely separate competing API root.

### 3. Favor explicit helper families

The new helpers should be grouped by usage pattern instead of added as unrelated one-offs:

- workflow helpers
- summary/report helpers
- dataset/demo helpers
- diagnostics/validation/export helpers

### 4. Optimize for discoverability

The best helpers are the ones a consumer can find quickly from autocomplete and docs. Naming should be concrete and task-oriented.

### 5. Preserve composability

Workflow helpers should reduce boilerplate, not hide the underlying engine models or prevent users from dropping to lower-level APIs when needed.

## Proposed Expansion

## Surface 1: `BKEngine` / `BKEngineOneLiner`

### Intent

Add app-facing workflow helpers that collapse common multi-step usage into one or two calls while still returning typed results.

### New helper categories

#### A. CSV-backed quick run helpers

These helpers reduce the amount of request setup needed when the caller already has CSV content or wants a local smoke test.

Examples:

- `BKEngine.runV3(csv:instrument:...)`
- `BKEngine.runV2(csv:instrumentID:config:...)`
- `BKEngine.runPreset(csv:symbol:preset:...)`

These should internally:

- parse CSV using existing parsing support
- create the minimum request/config objects needed
- delegate to existing engine/driver behavior
- return a typed `Result`

#### B. Bundled sample workflow helpers

Expand beyond the current `BKQuickDemo.runBundledSMACrossoverDemo(...)` into a small family of bundled-dataset helpers.

Examples:

- run bundled dataset with a named preset
- run all bundled datasets for a smoke-test matrix
- return a compact summary object instead of only raw backtest output

These are primarily for docs, tests, Playground usage, and onboarding.

#### C. Summary/report convenience helpers

Add a compact typed report layer for the most common app display needs.

Examples:

- build a summary from a `BacktestResult`
- build a summary directly from a v2 or v3 engine run
- return app-friendly headline metrics plus metadata

This avoids forcing every app consumer to manually derive the same presentation fields.

### Design constraint

Do not add overloads that duplicate too much internal orchestration logic. Centralize shared implementation behind private helpers so all workflow helpers remain thin wrappers over current engine behavior.

## Surface 2: `BacktestingKitManager`

### Intent

Add mid-level helpers that reduce boilerplate for repeated indicator/strategy/report composition without replacing the current low-level APIs.

### New helper categories

#### A. Indicator bundle helpers

The current manager exposes one-indicator-at-a-time methods. Add helpers for common bundles.

Examples:

- trend bundle: SMA/EMA combinations
- momentum bundle: RSI/MACD
- volatility bundle: Bollinger/ATR

These helpers should:

- apply multiple indicators in a predictable order
- return `[Candlestick]`
- use deterministic indicator keys

#### B. Strategy configuration helpers

The package already has many preset backtest functions. Add a small layer of reusable builders that make them easier to consume from app code.

Examples:

- helper to build common SMA/EMA crossover parameter sets
- helper to create common backtest option presets
- helper to run a strategy and immediately produce metrics in one call

This should favor reusable composition over creating another long list of highly specific strategy methods.

#### C. Metrics/report convenience helpers

The manager already has `buildMetricsReport`. Expand that into a small family of “result plus context” helpers.

Examples:

- equity curve + report bundle
- headline metrics helper
- trades plus metrics packaging helper

This gives app developers a cleaner bridge from simulation output to UI/reporting.

### Design constraint

Avoid turning `BacktestingKitManager` into an unbounded kitchen-sink class. Add only helpers that clearly compose existing indicators/strategies/reports and that match recurring user workflows.

## Surface 3: `BK*Tool`

### Intent

Make the tools more useful as app diagnostics and smoke-test primitives, not just isolated point functions.

### New helper categories

#### A. Validation preflight helpers

Add higher-level validation/report helpers for common onboarding checks.

Examples:

- CSV preflight plus parse stats
- combined validation and diagnostics summary
- strict/lenient comparison helper

These should help users answer “is this dataset safe to run?” quickly.

#### B. Export bundle helpers

Current export tools encode individual objects. Add small grouped exports for common app flows.

Examples:

- export summary package with trades + metrics + diagnostics
- export a demo run result as JSON and CSV payloads

#### C. Diagnostics wrappers

The diagnostics collector exists, but the flow into a “snapshot report” should be easier.

Examples:

- create a diagnostics session and return final snapshot
- summarize recent diagnostics events into a stable report model

#### D. Demo/smoke orchestration helpers

Add tool-level helpers that make it easy to run repeatable checks against bundled data and common presets.

Examples:

- smoke-test preset across one or more bundled datasets
- compare strict CSV validation + simulation readiness in one call

### Design constraint

Tool helpers should stay operational and side-effect-light. They should produce reports and exported payloads, not take over the simulation architecture.

## Proposed File Shape

This design should follow the existing layout and minimize churn.

### Existing files likely to extend

- `BacktestingKit/Engine/BKEngine.swift`
- `BacktestingKit/Engine/BKEngineOneLiner.swift`
- `BacktestingKit/Engine/BKQuickDemo.swift`
- `BacktestingKit/Engine/BacktestingKit.swift`
- `BacktestingKit/Tools/BKValidationTool.swift`
- `BacktestingKit/Tools/BKExportTool.swift`
- `BacktestingKit/Tools/BKDiagnosticsTool.swift`
- `BacktestingKit/Tools/BKScenarioTool.swift`

### New files likely to add

- `BacktestingKit/Engine/BKEngineHelperModels.swift`
- `BacktestingKit/Engine/BKEngineWorkflowHelpers.swift`
- `BacktestingKit/Engine/BKDemoWorkflowHelpers.swift`
- `BacktestingKit/Engine/BKManagerHelperModels.swift`
- `BacktestingKit/Tools/BKToolHelperModels.swift`
- `BacktestingKit/Tools/BKToolWorkflowHelpers.swift`

The exact split may change slightly during implementation, but the principle should hold:

- models/report types in focused helper-model files
- workflow wrappers in separate helper files
- preserve current file responsibilities where possible

## Public API Shape Recommendation

The helper expansion should cover three levels of abstraction.

### 1. One-step workflows

Best for onboarding and smoke tests.

Examples:

- run from bundled data
- run from inline CSV
- run a preset and return a summary
- validate + summarize readiness

### 2. Mid-level wrappers

Best for app developers integrating the package.

Examples:

- apply common indicator bundles
- build common strategy inputs
- build app-friendly summary models

### 3. Small utilities

Best for report generation and diagnostics.

Examples:

- derive headline metrics
- build export payloads
- summarize diagnostics snapshots

This mix matches the user requirement better than choosing only one helper style.

## Testing Strategy

Testing should follow the current XCTest-based style and stay close to the helper families.

### Add tests for:

- CSV-backed engine helpers returning typed success/failure
- bundled dataset helpers producing deterministic summaries
- manager indicator bundle helpers producing expected keys and counts
- manager report helpers packaging correct metrics
- tool-level validation/export/diagnostics helper reports
- smoke-test helpers staying deterministic on bundled datasets and fixed seeds

### Existing test files likely to extend

- `Tests/BacktestingKitTests/BacktestingKitEngineTests.swift`
- `Tests/BacktestingKitTests/BacktestingKitToolsTests.swift`

### New test files likely to add

- `Tests/BacktestingKitTests/BacktestingKitManagerHelperTests.swift`
- `Tests/BacktestingKitTests/BacktestingKitDemoWorkflowTests.swift`

## Documentation Updates

The helper expansion should be reflected in:

- `README.md`
- `docs/API_REFERENCE.md`
- `docs/GETTING_STARTED.md`
- `docs/AGENTIC_USAGE.md`
- optionally a new helper-focused guide if the surface grows enough

Docs should show:

- fastest path for app integration
- fastest path for local demo/smoke tests
- when to use workflow helpers versus lower-level APIs

## Risks

### 1. API sprawl

If every helper is added directly to existing types without grouping, discoverability will degrade. This is why helper-model and workflow-helper files should be introduced early.

### 2. Duplicate orchestration logic

Workflow helpers could accidentally fork existing engine logic. This must be avoided by delegating into the current drivers and parser paths.

### 3. Overfitting to demos

The bundled dataset helpers are important, but the first-class consumer remains app integration. Demo helpers must not dominate the expansion.

### 4. Unclear separation between manager helpers and tool helpers

Manager helpers should stay simulation/strategy/report oriented. Tool helpers should stay validation/export/diagnostics/report oriented.

## Recommended Execution Order

1. Add shared helper result/report models
2. Add app-facing `BKEngine` / one-liner workflow helpers
3. Add `BacktestingKitManager` mid-level helper bundles
4. Add `BK*Tool` operational helper workflows
5. Add tests for each helper family
6. Update docs and examples

## Acceptance Criteria

The expansion is successful when:

- app consumers can run common local and CSV-backed workflows with fewer setup steps
- demo/smoke-test users can run a broader deterministic helper matrix from bundled data
- manager-level users get reusable helper bundles instead of only one-off low-level methods
- tools expose more cohesive validation/export/diagnostics workflows
- all changes are additive and current public APIs continue to compile unchanged
- the new surface is documented and covered by tests
