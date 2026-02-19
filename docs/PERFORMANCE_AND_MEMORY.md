# Performance and Memory Guide

This guide focuses on iOS-oriented constraints while preserving parity behavior.

## Primary Levers

## Parser Mode

Use `BKSimulationExecutionOptions.parserMode`:

- `legacy`: baseline compatibility path
- `streamingLenient`: reduced peak memory for large CSVs
- `streamingStrict`: strict validation + streaming behavior

For large runs on mobile, prefer streaming modes.

## Batch Concurrency

`BKSimulationBatchOptions.maxConcurrency` controls memory pressure and throughput.

Guidance:

- iPhone class devices: start low (1-2), scale up after profiling.
- Mac CI: higher values are usually safe.

## Caching

Use `BKCachedCsvProvider` when repeatedly evaluating the same symbols/parameter tuples.

Observe:

- `BKCsvCacheStats`
- `BKCacheMetricsReporter`

Cache where request re-use is high; avoid unbounded growth for one-shot scans.

## Data Volume Controls

Use `BKSimulationExecutionOptions.maxBarsPerInstrument` to cap input size when needed.

This is useful for:

- bounded-memory previews
- quick diagnostics in UI

## Computation Considerations

- Prefer indicator precomputation once per run rather than repeated ad-hoc calculations.
- Avoid per-bar heavy allocations in custom extensions.
- Keep indicator keys deterministic and re-used to reduce map churn.

## Mobile Profiling Checklist

1. Measure baseline using demo dataset and one real dataset.
2. Compare `legacy` vs `streaming` parser peak memory.
3. Sweep `maxConcurrency` and identify throughput vs memory knee point.
4. Validate CPU hotspots in indicator/strategy closures.
5. Keep long-running runs cancellable in app orchestration.

## Safe Optimization Boundaries

Do optimize:

- parser path selection
- batching parameters
- provider caching
- off-main orchestration

Do not optimize by changing:

- v2/v3 model semantics
- parity-sensitive rule behavior
- parser strictness contract

## Release Performance Gates

Before release:

- run `swift build -c release`
- run `swift test`
- run at least one 10y/1d real dataset simulation per path used by your app
- run parity script if JS engine is available
