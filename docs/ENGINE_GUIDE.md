# Engine Guide

This guide documents the public execution surfaces and how they relate.

## Canonical Entry Point: `BKEngine`

`BKEngine` is the single source of truth for end-to-end runs.

- `BKEngine.runV3(_:)` → returns `Result<BKSimulationInstrumentReport, BKEngineFailure>`
- `BKEngine.runV2(_:)` → returns `Result<(BKV2.SimulateConfigOutput, PositionStatus), BKEngineFailure>`
- `BKEngine.runDemo(...)` → offline bundled CSV quick run for validation

It forwards to `BKEngineOneLiner` and keeps driver factories injectable.

### Driver Factories (Dependency Injection)

- `BKEngine.makeV3Driver`
- `BKEngine.makeV2Driver`

Use these to plug custom driver implementations for tests or alternative orchestration.

## One-Liner Requests

`BKEngine` reuses request models from `BKEngineOneLiner`:

- `BKEngine.V3Request` (`BKEngineOneLiner.BKV3Request`)
- `BKEngine.V2Request` (`BKEngineOneLiner.BKV2Request`)

### V3 Request Fields

- `instrument: BKV3_InstrumentInfo`
- `p1`, `p2`: strategy parameters forwarded to the configured flow
- `dateFormat`: parser date fallback format
- `executionOptions: BKSimulationExecutionOptions`
- `dataStore: BKV3DataStore`
- `csvProvider: BKRawCsvProvider`
- `log`: optional structured logging callback

### V2 Request Fields

- `instrumentID`
- `config: BKV2.SimulationPolicyConfig`
- `p1`, `p2`
- `dateFormat`
- `csvColumnMapping: BKCSVColumnMapping?`
- `csvProvider: BKRawCsvProvider`
- `log`: optional structured logging callback

## Driver Layer

### `BKSimulationDriver` (v3)

Key operations:

- `simulateInstrumentDetailed(...)`
- `simulateInstrumentsWithReport(...)`
- `simulateInstrumentsWithDetailedReport(...)`
- async progress stream support through `BKSimulationBatchRunHandle`

Batch options:

- `BKSimulationBatchOptions.maxConcurrency`
- `continueOnFailure`
- `useStreamingCsvParser`
- `strictCsvParsing`
- `csvColumnMapping`

Execution options:

- `BKSimulationExecutionOptions.parserMode` (`legacy`, `streamingLenient`, `streamingStrict`)
- `maxBarsPerInstrument`
- `csvColumnMapping`

### `BKV2SimulationDriver` (v2)

Key operation:

- `simulateInstrument(...)`

Responsibilities:

- fetch raw CSV via `BKRawCsvProvider`
- parse bars via `BKBarParsing`
- execute `v2simulateConfig(...)`

## Quick Demo Layer

### `BKQuickDemo`

Primary APIs:

- `runBundledSMACrossoverDemo(...)`
- `runAAPL10Y1DSMACrossover(...)`

Data source behavior:

- defaults to bundled CSV under `BacktestingKit/Resources`
- can override with caller-provided CSV

Outputs:

- `BKQuickDemoSummary` with date range, bar count, and `BacktestResult`

## Example Usage

```swift
import BacktestingKit

let result = await BKEngine.runV3(
    .init(
        instrument: instrument,
        p1: 5,
        p2: 20,
        dataStore: dataStore,
        csvProvider: provider
    )
)
```

```swift
import BacktestingKit

let demo = try BKEngine.runDemo(dataset: .aapl) { line in
    print(line)
}
```

## Entry Point Selection

- Use `BKEngine` for app integration.
- Use `BKSimulationDriver`/`BKV2SimulationDriver` when you need low-level orchestration.
- Use `BKQuickDemo` for smoke tests, CI sanity checks, and playground validation.
