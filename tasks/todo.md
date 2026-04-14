# Active Todo

## 2026-04-13 Documentation and Tutorial Completion

- [completed] Audit the beginner-facing markdown and DocC docs for overlap, stale examples, and unclear entry points.
- [completed] Reshape `README.md` into a lighter front door with one proof-of-success snippet, audience routing, and earlier tutorial links.
- [completed] Rewrite `docs/INDEX.md`, `docs/ONBOARDING.md`, `docs/GETTING_STARTED.md`, and `docs/CHOOSE_YOUR_SURFACE.md` so each page has one clear job.
- [completed] Align the DocC landing/tutorial order with the markdown onboarding path and add lightweight success checkpoints.
- [completed] Verify links and example accuracy with doc scans plus a Swift package build/test pass, then record review notes.

## 2026-04-13 Portfolio Orchestration API

- [completed] Review existing single-instrument, batch, import-review, and export seams for portfolio reuse.
- [completed] Add portfolio domain models plus a deep orchestration core for sleeve execution, weighting, rebalance interpretation, and aggregate reporting.
- [completed] Expose canonical `BKEngine` portfolio request/run APIs and app-facing `BKAppFacade` basket review/run helpers.
- [completed] Extend export/report helpers for portfolio JSON/CSV/Markdown outputs.
- [completed] Add focused tests for orchestration behavior, façade basket workflows, and portfolio exports.
- [completed] Run targeted verification, update roadmap/review notes, and summarize follow-up gaps.

## 2026-04-11 Xcode API Documentation Pass

- [completed] Review the current public API surface and existing documentation coverage.
- [completed] Identify public declarations that are missing Xcode doc comments.
- [completed] Add concise Xcode documentation comments to the full exposed API surface, including stored properties/constants.
- [completed] Verify documentation coverage with repo scans and a Swift package build/test pass.
- [completed] Record results and any follow-up gaps in the review notes below.

## Review

- Reshaped the beginner-facing docs so `README.md` is now a lighter front door, `docs/ONBOARDING.md` is the canonical markdown tutorial, `docs/GETTING_STARTED.md` is the compact quick reference, `docs/CHOOSE_YOUR_SURFACE.md` is the routing guide, and `docs/INDEX.md` is the docs map rather than a competing onboarding page.
- Promoted the existing DocC tutorial track by surfacing `BacktestingKit/BacktestingKit.docc` earlier in the markdown docs, reordering the DocC onboarding chapter around first success -> onboarding -> CSV import -> app integration, and adding lightweight success-oriented framing to the touched tutorial pages.
- Fixed stale onboarding/tutorial examples that still referenced `summary.result.totalReturn` or `summary.result.maxDrawdown` on `BKRunSummary`; the touched markdown and DocC examples now use `summary.metrics.*`.
- Shared tracking: opened and closed GitHub issue `#2` for the documentation/tutorial pass after posting the completion summary and verification notes.
- Verification scan: `rg -n 'summary\\.result\\.' README.md docs BacktestingKit/BacktestingKit.docc` returned no matches.
- Verification: `swift build`
- Verification: `swift test` passed with 122 tests and 0 failures.

- Implemented additive portfolio orchestration with new public portfolio request/result models, `BKEngine.runPortfolio(...)`, and a deep sleeve-execution core that resolves explicit, sleeve-driven, risk-parity, and risk-on/risk-off allocations.
- Added app-facing basket review/execution APIs with `BKAppFacade.buildPortfolioCSVImportScreenState(...)` and `BKAppFacade.runConfirmedPortfolioCSVImport(...)`, reusing the existing CSV inspection, inference, and normalization workflow for each sleeve.
- Added portfolio export/report helpers for JSON, CSV, and Markdown output so integrators can persist aggregate portfolio results, sleeve allocations, failures, and rebalance events without using export bundles as the primary runtime contract.
- Added portfolio-focused regression coverage for weighted aggregation, rebalance event generation, helper-driven weight resolution, partial failure vs. fail-fast behavior, app basket review readiness, confirmed run handoff, and portfolio export payloads.
- Verification: `swift build`
- Verification: `swift test --filter 'BacktestingKitPortfolioTests|BacktestingKitAppFacadeTests'`
- Verification: `swift test` passed with 122 tests and 0 failures.

- Added Xcode Quick Help comments for previously undocumented public declarations and stored properties/constants across the exposed package surface.
- Verification scan: no undocumented public `class`/`struct`/`enum`/`protocol`/`actor`/`typealias`/`func`/`init`/`subscript`/`var`/`let` declarations remain in `BacktestingKit/`.
- Coverage now includes large model and facade/helper surfaces that were previously missing field-level Quick Help.
- Verification: `swift test` passed with 111 tests and 0 failures after the full documentation sweep.
