# Models and Parity Contract

This document defines compatibility rules for v2/v3 model evolution.

## Contract Scope

Parity-sensitive contracts include:

- `BacktestingKit/Models/V2/*`
- `BacktestingKit/Models/V3/*`
- simulation output structures used by parity tooling
- rule and indicator naming conventions consumed by parity fixtures

## Hard Constraints

1. Existing v2/v3 fields should remain stable.
2. Behavioral changes in simulation/rule evaluation require parity re-baseline.
3. Additive fields are preferred over destructive changes.
4. Parser strictness (ISO8601 + chronological order) must remain explicit and test-covered.

## Allowed Changes

- Additive optional fields.
- New APIs that do not alter current execution path defaults.
- Internal refactors preserving output behavior.
- New metrics/analysis APIs outside parity-critical return payloads.

## Changes Requiring Extra Review

- Renaming/removing model fields in v2/v3 contracts.
- Changing default strategy/rule behavior for parity paths.
- Modifying parser defaults used by existing execution options.
- Altering output key semantics used by `tools/parity`.

## Adjusted Close Compatibility

Adjusted close is supported as optional input:

- `Candlestick.adjustedClose: Double?`
- `BKBar.adjustedClose: Double?`
- `BKCSVColumnMapping.adjustedClose: String?`

Because it is optional, historical parity flows remain intact unless callers opt in.

## Parity Workflow

Run:

```bash
bash tools/parity/run_parity.sh
```

Engine lookup order:

1. `JS_ENGINE_ROOT`
2. `../js-engine`
3. `../algotrade-js-trial`
4. `./js-engine`

The script validates Swift vs JS outputs with tolerance checks.

## Contributor Rules

- If parity-sensitive behavior changes, update fixtures intentionally and document the reason.
- Keep model changes small and isolated.
- Add tests for:
  - new optional fields
  - parser mapping changes
  - any non-trivial simulation behavior update
