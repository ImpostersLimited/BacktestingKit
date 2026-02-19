# Architecture Deep Dive

This document explains the internal layering and extension seams.

## Core Principles

- Keep v2/v3 model contracts parity-safe relative to the JavaScript engine.
- Separate data acquisition/parsing from simulation and analysis.
- Keep orchestration in `Engine/` and pure computations in `Core/`, `Analysis/`, `Indicators/`, `Rules/`.
- Favor protocol-based boundaries for substitution in tests and future integrations.

## Module Boundaries

## `Core/`

Contains foundational value models and generic simulation primitives:

- primary data models: `Candlestick`, `Trade`, `BacktestResult`, `BacktestMetricsReport`
- simulation primitives: `BKBar`, `BKStrategy`, rule closures, backtest loop
- risk/execution building blocks: `BKExecutionModel`, `BKPositionSizing`
- protocol-oriented extensions: `BKPriceBarRepresentable`, `BKTradeEvaluating`

## `Models/`

Data model namespace split by parity track:

- `Models/V2` for v2 simulation contracts
- `Models/V3` for v3 simulation contracts
- `Models/External` for shared tabular and series helpers

## `Indicators/`

Indicator calculators split by compatibility context:

- `Indicators/V2`
- `Indicators/V3`

## `Rules/`

Rule evaluators for strategy execution:

- `Rules/V2`
- `Rules/V3`

## `Simulation/`

Execution orchestration and batch behavior:

- `Simulation/V2/BKV2SimulationDriver`
- `Simulation/V3/BKSimulationDriver`
- shared protocol contracts in `Simulation/BKSimulationProtocols.swift`

## `Data/`

Input adapters and ingestion constraints:

- CSV parsing and mapping (`BKIO`, `BKBarParsing`)
- provider abstraction (`BKRawCsvProvider`)
- optional vendor adapter (`AlphaVantageClient`)
- cache and metrics (`BKCachedCsvProvider`, cache stats/reporting types)

## `Analysis/`

Post-run analytics and optimization:

- strategy post-analysis
- optimization and walk-forward helpers
- backtest core helpers

## `Engine/`

Public API and composition:

- canonical entry point: `BKEngine`
- one-liner orchestration: `BKEngineOneLiner`
- presets and strategy factory
- advanced indicators/strategies/performance evaluators

## Dependency Direction

Preferred dependency flow:

`Engine` -> `Simulation` -> `Rules`/`Indicators` -> `Core`

`Data` is consumed by `Simulation` and sometimes `Engine`.

`Analysis` consumes `Core` and simulation outputs.

`Models` are shared contracts and should not depend on higher layers.

## Protocol Boundaries (POP + SOLID)

Key abstractions:

- `BKBarParsing`
- `BKRawCsvProvider`
- `BKV2SimulationDriving`
- `BKV3SimulationDriving`
- `BKBacktestMetricsCalculating`
- `BKPositionSizingModel`
- `BKSlippageModel`
- `BKCommissionModel`

These keep the system open for extension and support narrow-scope testing.

## Error Semantics

The architecture distinguishes:

- parsing/data errors (`BKCSVParsingError`)
- provider/network errors (`AlphaVantageClientError`)
- orchestration failures (`BKEngineFailure`, `BKSimulationRunFailure`)
- input validation failures (`BKSimulationDriverError`)

This allows UI layers to handle retries, messaging, and recovery with explicit context.

## Non-Goals

- no hard coupling to one market data vendor
- no mutation of v2/v3 contract behavior without parity validation
- no hidden parser normalization that can mask bad input (strict mode is explicit)
