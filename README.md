# BacktestingKit

BacktestingKit is a Swift framework for deterministic backtests and simulation workflows with v2 and v3 parity-oriented execution paths.

Current release track: **v0.1.0**.

## Who This Is For

- App integrators who want to start with `BKAppFacade` and move to `BKEngine` only when they need lower-level control.
- Engine integrators who want direct v2/v3 request-model execution through `BKEngine`.
- Candle-first workflows that already have normalized `Candlestick` data and want `BacktestingKitManager`.
- Diagnostics/export/parity workflows that need the tool helpers.

## Project Structure

- `BacktestingKit/Core` – foundational shared types.
- `BacktestingKit/Models` – v2/v3/external model definitions.
- `BacktestingKit/Data` – CSV parsing, providers, cache, AlphaVantage support.
- `BacktestingKit/Simulation` – v2/v3 simulation entrypoints and drivers.
- `BacktestingKit/Engine` – presets, high-level engine APIs, manager workflows.
- `BacktestingKit/Tools` – validation, diagnostics, export, comparison, scenario, and parity helpers.

Architecture notes live in `BacktestingKit/ARCHITECTURE.md`.

## Start Here

- New to the package: [docs/ONBOARDING.md](docs/ONBOARDING.md)
- Want the shortest install/build/run checklist: [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md)
- Not sure which API surface to use: [docs/CHOOSE_YOUR_SURFACE.md](docs/CHOOSE_YOUR_SURFACE.md)
- Want the full docs map: [docs/INDEX.md](docs/INDEX.md)
- Want guided interactive tutorials in Xcode: open `BacktestingKit/BacktestingKit.docc`

## First Success

Build the package:

```bash
swift build
```

Then run the smallest offline success path:

```swift
import BacktestingKit

let result = BKEngine.runDemo(dataset: .aapl)

switch result {
case .success(let summary):
    print(summary.symbol)
    print(summary.barCount)
    print(summary.metrics.totalReturn)
case .failure(let error):
    print(error.localizedDescription)
}
```

Success looks like:

- the package builds locally
- bundled CSV resources load without provider wiring
- you get a `BKRunSummary` back and can inspect `summary.metrics.totalReturn`

If you want the full beginner path after this, go to [docs/ONBOARDING.md](docs/ONBOARDING.md).

## Choose Your Surface

- `BKAppFacade`
  Start here if your app begins with pasted, uploaded, or reviewed CSV and you want one app-facing namespace.
- `BKEngine`
  Use this when you need direct v2/v3 request-model control and provider-driven execution.
- `BacktestingKitManager`
  Use this when you already have candles and want indicator bundles, strategy recipes, and summary/report helpers.
- Tool helpers
  Use `BKValidationTool`, `BKExportTool`, `BKComparisonTool`, `BKScenarioTool`, and `BKParityTool` for validation, export, comparison, smoke scenarios, and parity checks.

The fuller decision guide is in [docs/CHOOSE_YOUR_SURFACE.md](docs/CHOOSE_YOUR_SURFACE.md).

## Documentation

### Beginner Path

- [docs/ONBOARDING.md](docs/ONBOARDING.md) – the canonical markdown tutorial from build to app integration
- [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) – the compact quick reference after installation
- [docs/CHOOSE_YOUR_SURFACE.md](docs/CHOOSE_YOUR_SURFACE.md) – the routing guide for `BKAppFacade`, `BKEngine`, manager workflows, and tools

### Guided Interactive Tutorials

- `BacktestingKit/BacktestingKit.docc` – DocC tutorial bundle for install, first success, CSV import, app integration, first backtest, and follow-on workflows

### Reference and Deep Dives

- [docs/INDEX.md](docs/INDEX.md) – complete documentation map
- [docs/PACKAGE_USAGE_GUIDE.md](docs/PACKAGE_USAGE_GUIDE.md) – workflow-oriented package usage map
- [docs/ENGINE_GUIDE.md](docs/ENGINE_GUIDE.md) – canonical `BKEngine`, drivers, and execution flows
- [docs/DATA_INGESTION.md](docs/DATA_INGESTION.md) – CSV parsing, mappings, providers, and normalization
- [docs/HELPER_WORKFLOWS.md](docs/HELPER_WORKFLOWS.md) – additive helper and façade workflows
- [docs/TOOLS.md](docs/TOOLS.md) – validation, diagnostics, export, comparison, scenario, and parity helpers
- [docs/INDICATORS_STRATEGIES_METRICS.md](docs/INDICATORS_STRATEGIES_METRICS.md) – manager-owned indicator, strategy, and metrics workflows

## Parity

Run the parity check with:

```bash
bash tools/parity/run_parity.sh
```

If your local JS engine checkout is not in a default location, set:

```bash
JS_ENGINE_ROOT=../js-engine bash tools/parity/run_parity.sh
```

Expected success output:

- `PARITY_OK`
- `Parity check passed.`

## Open Source Metadata

- License: `LICENSE` (MIT)
- Contribution guide: `CONTRIBUTING.md`
- Code of conduct: `CODE_OF_CONDUCT.md`
- Security policy: `SECURITY.md`
- Support policy: `SUPPORT.md`
- Changelog: `CHANGELOG.md`
- Authors: `AUTHORS.md`
- GitHub templates/workflows: `.github/`
