# BacktestingKit Documentation Index

This directory contains the markdown companion docs for BacktestingKit. Use this page as the map, not as another onboarding guide.

## Pick Your Start

- New to the package: `ONBOARDING.md`
- Already installed and want the shortest route to first success: `GETTING_STARTED.md`
- Not sure whether to use `BKAppFacade`, `BKEngine`, manager workflows, or tools: `CHOOSE_YOUR_SURFACE.md`
- Want the workflow-oriented package map: `PACKAGE_USAGE_GUIDE.md`
- Want guided interactive tutorials in Xcode: open `BacktestingKit/BacktestingKit.docc`

## Recommended Beginner Order

1. `ONBOARDING.md` — the canonical markdown tutorial from build to app integration.
2. `CHOOSE_YOUR_SURFACE.md` — the decision guide once you know the package basically works.
3. `HELPER_WORKFLOWS.md` — helper-first and façade-first app flows.
4. `ENGINE_GUIDE.md` — canonical `BKEngine` request-model execution.
5. `DATA_INGESTION.md` — CSV parsing, mappings, providers, and normalization.
6. `INDICATORS_STRATEGIES_METRICS.md` or `TOOLS.md` — depending on whether you need manager workflows or tooling workflows next.

## Workflow Guides

- `ONBOARDING.md` — the linear beginner path for learning the package.
- `GETTING_STARTED.md` — quickest route from clone to first successful run.
- `CHOOSE_YOUR_SURFACE.md` — quick routing guide across the main package surfaces.
- `PACKAGE_USAGE_GUIDE.md` — one document that explains when to use each major package surface.
- `HELPER_WORKFLOWS.md` — additive convenience layer for app and smoke-test workflows, including `BKAppFacade`.
- `ENGINE_GUIDE.md` — v2/v3 engine entrypoints, requests, drivers, and batch orchestration.
- `TOOLS.md` — validation, diagnostics, export, comparison, benchmark, scenario, and parity helpers.
- `INDICATORS_STRATEGIES_METRICS.md` — manager-owned indicators, strategy recipes, analytics, and preset philosophy.

## Reference and Deep Dives

- `API_REFERENCE.md` — symbol-oriented API inventory with grouping by module.
- `ARCHITECTURE_DEEP_DIVE.md` — module boundaries, layering, and design constraints.
- `MODELS_AND_PARITY.md` — v2/v3 parity contract and model compatibility rules.
- `AGENTIC_USAGE.md` — instructions for using BacktestingKit with agentic coding/automation tools.
- `ERROR_HANDLING_AND_DIAGNOSTICS.md` — error taxonomy and UI-facing failure handling.
- `PERFORMANCE_AND_MEMORY.md` — memory/performance guidance and optimization levers.
- `EXTENDING_BACKTESTINGKIT.md` — extension points for providers, parsers, drivers, and analytics.

## Operations and Release Docs

- `../ROADMAP.md` — master checklist for all planned/completed engine work.
- `PARITY_TESTING.md` — JS parity runner setup and expectations.
- `RELEASE_CHECKLIST.md` — release gate checklist.
- `RELEASE_NOTES_v0.1.0.md` — prepared GitHub release notes for `v0.1.0`.
- `OPEN_SOURCE_MAINTAINERS.md` — maintenance policy and contribution standards.
