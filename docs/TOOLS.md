# Tools and Helpers

This document describes additive utility tools exposed by BacktestingKit.
These tools do not alter v2/v3 engine model shapes or parity behavior.

## Integration order (recommended)

1. Validate input (`BKValidationTool`)
2. Emit lifecycle diagnostics (`BKDiagnosticsCollector`)
3. Run engine (`BKEngine.runV2` / `BKEngine.runV3`)
4. Export payloads (`BKExportTool`)
5. Compare run summaries (`BKComparisonTool`)
6. Benchmark/parity checks in CI (`BKBenchmarkTool`, `BKParityTool`)

## `BKValidationTool`

Purpose: Preflight validation before execution.

- `validateCSV(_:columnMapping:)`
  - Verifies strict CSV parseability (ISO8601 date, chronological order, required columns).
  - Returns `BKValidationReport` with structured `BKValidationIssue` entries.
- `validateV2Request(_:)`
  - Validates `BKEngine.V2Request` shape (empty IDs, suspicious period ranges).
- `validateV3Request(_:)`
  - Validates `BKEngine.V3Request` shape.

Output types:

- `BKValidationSeverity`
- `BKValidationIssue`
- `BKValidationReport`

Example:

```swift
let validation = BKValidationTool.validateCSV(csvText, columnMapping: nil)
guard validation.isValid else {
    // Show validation.issues in UI
    return
}
```

## `BKDiagnosticsCollector`

Purpose: Capture structured lifecycle events for UI and troubleshooting.

- `append(_:)`
- `emit(kind:stage:message:metadata:)`
- `snapshot()`
- `clear()`

Event types:

- `BKDiagnosticEventKind`
- `BKDiagnosticEvent`

Example:

```swift
let diagnostics = BKDiagnosticsCollector()
await diagnostics.emit(kind: .validationStarted, stage: "validation", message: "CSV preflight")
```

## `BKBenchmarkTool`

Purpose: Measure latency and optional memory deltas for repeatable micro-benchmarks.

- `run(name:iterations:warmup:measureMemory:block:)`
- `runAsync(name:iterations:warmup:measureMemory:block:)`

Result types:

- `BKBenchmarkSample`
- `BKBenchmarkResult`

Example:

```swift
let bench = BKBenchmarkTool.run(name: "parse-csv", iterations: 20) {
    _ = csvToBarsStreaming(csvText, reverse: false, strict: true)
}
```

## `BKParityTool`

Purpose: Compare expected/actual numeric metrics with a tolerance.

- `compareMetrics(expected:actual:tolerance:)`
- `compareAnalysis(expected:actual:tolerance:)`

Result types:

- `BKParityMismatch`
- `BKParityReport`

Example:

```swift
let report = BKParityTool.compareMetrics(expected: baseline, actual: candidate, tolerance: 1e-6)
if !report.isMatch {
    // show report.mismatches
}
```

## `BKScenarioTool`

Purpose: Deterministic synthetic scenario generation for reproducible simulation tests.

- `generateCandles(config:)`
- `run(config:)`
- `defaultSmokeConfigs()`
- `validate(config:)`
- `summarize(config:)`
- `runExportBundle(config:diagnostics:prettyPrinted:)`
- `smokeSuite(configs:)`

Config/result types:

- `BKScenarioStrategy`
- `BKScenarioConfig`
- `BKScenarioResult`
- `BKScenarioReadinessReport`
- `BKScenarioSmokeCaseReport`
- `BKScenarioSmokeSuiteReport`

Example:

```swift
let scenario = BKScenarioTool.run(config: BKScenarioConfig(seed: 42))
print(scenario.backtest.totalReturn)
```

## `BKComparisonTool`

Purpose: Compare compact helper summaries for regressions and smoke-test review.

- `diffSummaries(baseline:candidate:)`
  Produces a structured summary diff including headline metric deltas.
- `compareRuns(baseline:candidate:tolerance:)`
  Flags whether summary differences exceed a caller-supplied tolerance.
- `assertEquivalent(baseline:candidate:tolerance:)`
  Throws `BKComparisonAssertionError` when summary differences exceed the allowed tolerance.

Output types:

- `BKRunMetricDiff`
- `BKRunSummaryDiff`
- `BKRunComparisonReport`
- `BKComparisonAssertionError`

Example:

```swift
let report = BKComparisonTool.compareRuns(
    baseline: baselineSummary,
    candidate: candidateSummary,
    tolerance: 0.001
)
```

## `BKExportTool`

Purpose: Stable payload export for downstream tooling/UI.

- `toJSON(_:prettyPrinted:)`
- `tradesToCSV(_:)`
- `exportPreflight(_:trades:prettyPrinted:)`
- `exportRunBundle(summary:trades:diagnostics:scenario:prettyPrinted:)`
- `exportMarkdownSummary(_:,title:)`

Error type:

- `BKExportError`

Example:

```swift
let export = BKExportTool.tradesToCSV(trades)
let json = BKExportTool.toJSON(analysis)
```

## UI-facing error behavior

- Tools return `Result` and typed errors where relevant.
- Validation returns structured issue arrays instead of throwing.
- Export failures are surfaced as `BKExportError`.

## CI usage pattern

- Run benchmark and parity helpers in deterministic mode (fixed seeds/tolerances).
- Keep tolerances explicit in parity checks per metric family.
- Store benchmark outputs as artifacts for release-to-release comparison.
