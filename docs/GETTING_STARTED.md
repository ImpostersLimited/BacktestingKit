# Getting Started

For full documentation map, start at `docs/INDEX.md`.

## Requirements

- Xcode with Swift toolchain support for this project.
- macOS environment with command-line tools installed.
- Optional: Node.js + local JS engine checkout for parity checks in `tools/parity`.

## Build

```bash
xcodebuild -scheme BacktestingKit -project BacktestingKit.xcodeproj -configuration Debug build
```

## Core Entry Points

`BKEngine` is the canonical public entrypoint for engine usage.

- `BKEngine.runV3(...)` for v3 one-shot execution.
- `BKEngine.runV2(...)` for v2 one-shot execution.
- `BKEngine.runDemo(...)` for bundled quick validation.

Lower-level entrypoints remain available for advanced usage:

- V3 driver: `BKSimulationDriver`
- V2 driver: `BKV2SimulationDriver`
- V3 simulate: `v3simulateConfig`
- V2 simulate: `v2simulateConfig`

## Minimal V3 Flow

1. Get raw CSV data (`BKRawCsvProvider` or custom provider).
2. Parse to bars (`csvToBars` or `csvToBarsStreaming`).
3. Build rules/config models (`BKV3_*`).
4. Run simulation via `BKSimulationDriver` or direct `v3simulateConfig`.
5. Run post-analysis (`v3postAnalysis`) if needed.

## Batch Simulation

Use `simulateInstrumentsWithDetailedReport(...)` to get:

- Per-instrument reports.
- Structured failures (`BKEngineFailure`) with error stage/code metadata.
- Progress callback support via `BKSimulationProgress`.

## Notes

- Keep v2/v3 models unchanged if you need strict JavaScript parity.
- For custom sources, normalize CSV before parsing and preserve chronological order.
- Full parity requires a local JS engine path (`../js-engine`, `../algotrade-js-trial`, or `JS_ENGINE_ROOT`).
