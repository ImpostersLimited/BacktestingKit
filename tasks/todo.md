# Active Todo

## 2026-04-15 Follow-up Review Comment Fixes

- [completed] Reproduce the fail-fast portfolio summary bug and the explicit zero-total review-state bug with failing regression tests.
- [completed] Update portfolio orchestration so fail-fast runs still resolve weights before finalization.
- [completed] Extend app-facing portfolio review validation to reject explicit allocations whose clamped total is not positive.
- [completed] Re-run targeted and full Swift test verification, then record the result.

## 2026-04-15 Review Comment Fixes

- [completed] Reproduce the two PR review comments with failing tests for explicit zero-total allocations and portfolio review-state validation.
- [completed] Update portfolio allocation resolution so invalid explicit zero-total weights fail instead of silently equal-weighting successful sleeves.
- [completed] Add portfolio-level validation to the app-facing review state for duplicate symbols and explicit weight-count mismatches.
- [completed] Re-run targeted and full test verification after the fix.

## 2026-04-15 Release Prep

- [completed] Audit release-facing metadata, roadmap/checklist state, and current verification evidence.
- [completed] Update `CHANGELOG.md` and prepare patch-track release notes without forcing a final tag name early.
- [completed] Sync `ROADMAP.md` and `docs/RELEASE_CHECKLIST.md` with the completed docs/tutorial and CI work.
- [completed] Re-run release-prep verification and record what remains intentionally manual.

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

- Added regression coverage for two review-reported cases: explicit allocations that collapse to a non-positive total across successful sleeves, and app-facing basket review states that previously ignored duplicate-symbol and explicit-weight-count portfolio constraints.
- `BKPortfolioOrchestration` now keeps zero weights and emits a `portfolio-allocation` failure for invalid explicit zero-total allocations instead of silently converting them into equal-weight runs.
- `BKAppFacade.buildPortfolioCSVImportScreenState(...)` now adds portfolio-scoped validation issues and marks the basket invalid before execution when duplicate sleeve symbols or explicit weight-count mismatches are present.
- Verification: `swift test --filter 'BacktestingKitPortfolioTests/testRunPortfolioRejectsExplicitWeightsWhenSuccessfulSleevesResolveToNonPositiveTotal|BacktestingKitAppFacadeTests/testBuildPortfolioCSVImportScreenStateRejectsDuplicateSleeves|BacktestingKitAppFacadeTests/testBuildPortfolioCSVImportScreenStateRejectsExplicitWeightCountMismatch'`
- Verification: `swift test --filter 'BacktestingKitPortfolioTests|BacktestingKitAppFacadeTests'`
- Verification: `swift test` passed with 125 tests and 0 failures.

- Added follow-up regression coverage for two more review-reported cases: fail-fast portfolio runs now resolve processed successful-sleeve weights before finalization, and portfolio import review now rejects explicit allocations whose clamped total is not positive.
- `BKPortfolioOrchestration` no longer returns early on fail-fast failures before weight resolution; it breaks out, resolves weights against the full request, and finalizes with correct resolved weights and aggregate metrics for the already-successful sleeves.
- `BKAppFacade.buildPortfolioCSVImportScreenState(...)` now emits `portfolio_explicit_weight_total_invalid` when explicit review weights clamp to a non-positive total, so `isReadyToContinue` no longer advertises a deterministically invalid run as ready.
- Verification: `swift test --filter 'BacktestingKitPortfolioTests/testRunPortfolioFailFastResolvesSuccessfulSleeveWeightsBeforeFinalization|BacktestingKitAppFacadeTests/testBuildPortfolioCSVImportScreenStateRejectsExplicitWeightTotalThatIsNotPositive'`
- Verification: `swift test --filter 'BacktestingKitPortfolioTests|BacktestingKitAppFacadeTests'`
- Verification: `swift test` passed with 127 tests and 0 failures.

- Prepared the current patch-track release metadata with an unreleased changelog entry, a new `docs/RELEASE_NOTES_v0.1.x.md` draft, and doc index/readme references that no longer hardcode `v0.1.0` as the active release track.
- Synced the release lane in `ROADMAP.md` to reflect the work that is actually complete: API naming audit, DocC final pass, CI matrix finalization, and prepared `v0.1.x` release notes.
- Left the publish-time steps in `docs/RELEASE_CHECKLIST.md` intentionally unchecked because tag creation, GitHub release publication, and contributor announcement are still explicit manual release actions.
- Shared tracking: opened, updated, and closed GitHub issue `#3` for this release-prep pass after recording the final verification summary.
- Verification: `swift build`
- Verification: `swift build -c release`
- Verification: `swift test` passed with 122 tests and 0 failures.
- Verification: `swift run BacktestingKitTrialDemo` exited successfully.
- Verification: `bash tools/parity/run_parity.sh` correctly reported that no local JS engine checkout is present, so parity remains an environment-dependent release gate rather than a package failure in this worktree.
- Release candidate branch pushed: `codex/release-prep-v0.1.x`
- Draft PR opened: `#4`
- Final public tag/release intentionally paused pending one decision: release `v0.1.1` directly from this branch or merge to `main` first. The parity baseline announcement also still needs an explicit JS engine revision if we want that checklist item fully closed.

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
