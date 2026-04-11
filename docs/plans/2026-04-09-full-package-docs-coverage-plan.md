# 2026-04-09 Full Package Docs Coverage Plan

## Goal

Produce a package-level documentation pass that teaches the real current usage of BacktestingKit across all major public surfaces, with no API changes.

## Coverage Targets

1. Installation and first-run onboarding
2. Offline helper workflows and bundled demos
3. `BKEngine` and `BKEngineOneLiner` request-driven execution
4. Data ingestion and CSV/provider customization
5. `BacktestingKitManager` indicator, strategy, and recipe workflows
6. Tooling workflows for validation, diagnostics, export, scenarios, comparison, benchmark, and parity
7. Lower-level driver and batch simulation usage
8. Analysis, metrics, optimization, and extension entrypoints
9. DocC tutorial coverage for the most important package workflows

## Planned Outputs

- A new package usage guide that organizes the package by "what are you trying to do?"
- README updates so users can discover the right doc path quickly
- `docs/INDEX.md` updates to act as a real navigation hub
- DocC tutorial refreshes so examples match the current Result-based APIs
- Additional DocC tutorials for helper workflows, manager workflows, and tools

## Constraints

- No breaking changes
- Documentation examples must reflect the current codebase
- Prefer additive docs that cross-link to existing deep dives instead of duplicating every detail
- Keep the package reference docs and tutorial docs aligned

## Verification

- Read the updated docs against the actual public APIs used in examples
- Run targeted repo scans for stale examples (`try BKEngine.runDemo`, throwing provider examples, outdated helper names)
- Ensure new docs are discoverable from README and `docs/INDEX.md`
