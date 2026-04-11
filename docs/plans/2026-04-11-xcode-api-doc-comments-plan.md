# 2026-04-11 Xcode API Doc Comments Plan

## Goal

Add Xcode-compatible documentation comments to the BacktestingKit public API surface so exposed symbols have usable Quick Help without changing runtime behavior.

## Scope

- Public and open declarations in `BacktestingKit/`
- Type, method, property, initializer, and typealias surfaces that are part of the shipped package API
- Existing public APIs only; no functional changes

## Approach

1. Inventory public declarations and identify symbols that do not already have adjacent doc comments.
2. Add short, behavior-focused `///` comments only where coverage is missing.
3. Prefer concise summaries plus parameter/returns notes for non-obvious functions.
4. Keep edits additive and localized to the files that expose public APIs.

## Verification

- Re-scan the package for public declarations without adjacent doc comments.
- Run a Swift package verification command to catch syntax or formatting regressions.

## Risks

- Heuristic scans can miss edge cases such as grouped declarations inside public extensions.
- Some legacy APIs have broad surfaces, so consistency matters more than exhaustive prose.
