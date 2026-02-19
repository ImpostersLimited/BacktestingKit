# Extending BacktestingKit

This document covers extension points intended for customization without parity breakage.

## Extension Strategy

Use additive extensions and protocol implementations instead of mutating existing v2/v3 flow contracts.

## Data Source Extension

Implement `BKRawCsvProvider`:

```swift
struct MyCsvProvider: BKRawCsvProvider {
    func getRawCsv(ticker: String, p1: Double, p2: Double) async throws -> String {
        // Return CSV text in required schema/order.
    }
}
```

Then inject via:

- `BKEngine.V2Request.csvProvider`
- `BKEngine.V3Request.csvProvider`
- or driver initializer

## Parser Extension

Implement `BKBarParsing` and inject into drivers for custom ingestion behavior.

Default parser:

- `BKCSVBarParser`

Use custom parser only when you need a controlled deviation from stock CSV parsing flow.

## Driver Substitution

You can replace run orchestration by setting:

- `BKEngine.makeV2Driver`
- `BKEngine.makeV3Driver`

This is useful for:

- integration tests
- instrumentation wrappers
- alternative queueing/retry strategies

## Strategy Extension

For custom rule logic:

- build `BKStrategy` with custom `entryRule` / `exitRule`
- optionally provide `prepIndicators`
- run through core `backtest(strategy:inputSeries:options:)`

For candle-based strategy helpers, add methods on `BacktestingKitManager` in the style of `BKAdvancedStrategies.swift`.

## Execution and Cost Models

Implement:

- `BKSlippageModel`
- `BKCommissionModel`

Then apply with `executionAdjustedTrades(...)` for net-PnL evaluation.

## Position Sizing Models

Implement `BKPositionSizingModel` for custom risk budgeting approaches.

Example built-in:

- `BKVolatilityTargetingSizer`

## Metrics Pipeline Extension

For report-level metrics:

- start with `BacktestMetricsReport`
- derive additional structures in additive APIs

For replacing report internals:

- implement `BKBacktestMetricsCalculating`
- inject into `BacktestingKitManager` (internal initializer pattern used in tests)

## Backward Compatibility Rules

When extending:

- keep existing public signatures stable unless adding new overloads
- avoid changing indicator key semantics consumed by existing rules
- keep new fields optional where possible
- add tests and parity checks for behavior-sensitive changes
