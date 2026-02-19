# ``BacktestingKit``

Production-grade Swift backtesting engine with v2/v3 parity paths, strict CSV ingestion, and extensible strategy analytics.

## Overview

Use BacktestingKit to run deterministic strategy simulations with:

- Canonical one-shot entry points via ``BKEngine``
- Strict date/ordering-safe CSV parsing
- v2 and v3 simulation compatibility paths
- Extensible indicator, strategy, and metrics layers

## Tutorials

- <doc:BacktestingKitTutorials>

## Topics

### Engine

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
