# BacktestingKit Module Layout

This framework is now organized by responsibility so simulation features can scale without changing model parity.

- `Core/`
  - Fundamental shared types and primitives (`BKTypes`, candlestick/trade/backtest value models, small utilities).
- `Models/`
  - `V2/`: v2 data models.
  - `V3/`: v3 data models.
  - `External/`: shared tabular-series helper models.
- `Indicators/`
  - `V2/` and `V3/` indicator calculators.
- `Rules/`
  - `V2/` and `V3/` rule evaluators.
- `Simulation/`
  - `V2/` and `V3/` simulation engines and driver entrypoints.
- `Data/`
  - IO, CSV parsing, raw provider clients, and cache metrics.
- `Analysis/`
  - Post-analysis and optimization utilities.
- `Engine/`
  - Strategy/preset orchestration and high-level API surface.
- `Support/`
  - Conversion/coding helpers used across modules.

## Compatibility goals

- Model shape and behavior for v2/v3 remain feature-parity with the JavaScript engine.
- Parsing behavior remains strict for ISO8601 dates and chronological data ordering.
- Optional CSV column mapping supports custom OHLCV header names without changing simulation internals.
