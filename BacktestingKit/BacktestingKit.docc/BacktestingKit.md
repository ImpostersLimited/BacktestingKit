# ``BacktestingKit``

Production-grade Swift backtesting engine with v2/v3 parity paths, strict CSV ingestion, and extensible strategy analytics.

## Overview

Use BacktestingKit to run deterministic strategy simulations with:

- Beginner app-facing workflows via ``BKAppFacade``
- Import-review screen state via ``BKAppFacade/buildCSVImportScreenState(symbol:csv:maxRows:)``
- Explicit CSV auto-inference for app-side import flows
- Canonical one-shot entry points via ``BKEngine``
- Strict date/ordering-safe CSV parsing
- v2 and v3 simulation compatibility paths
- Extensible indicator, strategy, and metrics layers

Start with the tutorials below if you are new to the package. The recommended order is install and first success, onboarding, CSV import, app integration, first backtest, and then the helper, manager, and tooling follow-ons.

## Tutorials

- <doc:BacktestingKitTutorials>

## Topics

### Engine

- ``BKAppFacade``
- ``BKEngine``
- ``BKEngineOneLiner``
- ``BKQuickDemo``

### Simulation

- ``BKSimulationDriver``
- ``BKV2SimulationDriver``
- ``BKSimulationBatchOptions``
- ``BKSimulationExecutionOptions``

### Data and Parsing

- ``BKRawCsvProvider``
- ``BKCSVColumnMapping``
- ``BKCSVParsingError``
- ``csvToBars(_:dateFormat:reverse:strict:columnMapping:)``
- ``csvToBarsStreaming(_:dateFormat:reverse:strict:columnMapping:)``

### Core Analytics

- ``BacktestingKitManager``
- ``BacktestResult``
- ``BacktestMetricsReport``
- ``BKAdvancedPerformanceMetrics``
