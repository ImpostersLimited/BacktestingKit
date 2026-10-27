# Active Todo

## 2026-10-27 Publish Maintenance Release v0.2.5

- [x] Inspect the complete diff, real main checkout, and remote releases/tags; derive v0.2.5 from remote v0.2.4.
- [ ] Record release notes, commit the reviewed maintenance changes, and push the feature branch.
- [ ] Run the hosted debug/release matrix with stable Xcode and request Codex review; resolve any failures.
- [ ] Fast-forward the clean main checkout, push main, and publish the annotated v0.2.5 tag/release.
- [ ] Verify remote main/tag convergence, checkout cleanliness, and release metadata; remove temporary files.

### Verification Plan

- Use the normal hosted macOS runner plus explicitly selected stable Xcode 27.1; run debug/release build/tests with complete concurrency checking and compiler warnings treated as errors.
- The existing `issue-intake` workflow auto-assigns/issues Project placement. Track this publication in its pull request without creating or assigning an issue.
- Only workflows, the changelog, and the active todo belong in this release; library API, minimum Swift version, and deployment targets stay unchanged.

## 2026-10-27 Routine Swift Maintenance

- [x] Compare package configuration, installed stable tools, and current official Swift/API release guidance.
- [x] Verify current Swift compilation with strict Swift 6 diagnostics and compiler warnings treated as errors.
- [x] Apply only confirmed maintenance fixes, preserving Swift 5.9 and deployment compatibility.
- [x] Verify workflow syntax/matrix and the final diff; document findings and limitations.
- [ ] Run the full debug/release test suite with stable Xcode 27.1 (blocked locally: only Xcode 27.2 RC is installed and Command Line Tools lacks `xctest`).

### Scope

- Remote main matches this checkout at ac2ceb4. Apple identifies installed Xcode 27.2 (27B48) as an RC; its initial test run was stopped and is not a stable verification result.
- Stable Xcode 27.1 (27A9275) is not installed locally. Command Line Tools provides released Swift 6.4 (swiftlang-6.4.0.34.1) and the macOS 26.5 SDK for package compilation checks.
- No third-party Swift package dependencies. Evaluate new Swift features against actual call sites before changing the minimum toolchain or API.
- Baseline CI ran debug tests even in its release job and did not enforce complete concurrency checking.
- Preserve normal macOS-runner compatibility checks and add explicit stable Xcode 27.1 checks on GitHub's `xcode-27` runner; update checkout/github-script actions after reviewing their breaking changes.
- Swift 6.4's new Swift Build backend warns when `-Xswiftc -swift-version` overrides manifest language settings. CI will use complete concurrency checking in the declared language mode instead of introducing that warning or raising the minimum toolchain.
- GitHub connector needs reauthentication. The active issue-intake workflow also auto-assigns/adds new issues to a Project, contrary to the current tracking policy; no issue was created.

### Review

- Reviewed Swift 6.4 release/API guidance and current Swift/Foundation call sites. No required library API migration or third-party Swift dependency update was identified. Keep tools-version 5.9, iOS 16, and macOS 13 compatibility; new collection, observation, and async-cleanup features do not justify changing that baseline.
- CI now builds/tests debug and release on the normal runner and stable Xcode 27.1, with complete concurrency checking and compiler warnings treated as errors. Release jobs now actually run release tests; optional JS parity runs only once.
- Updated `actions/checkout` v4 -> v7 and `actions/github-script` v7 -> v9. Existing scripts use neither the removed CommonJS import nor conflicting `getOctokit` declarations; their behavior is unchanged.
- Command Line Tools Swift 6.4 with macOS 26.5 SDK: `swift build -c release --sdk /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk -Xswiftc -swift-version -Xswiftc 6 -Xswiftc -warnings-as-errors` passed. Library/compiler diagnostics were clean; Swift Build emitted language-override, missing CLT linker search-path, and existing `.build/release` symlink warnings. These tool/layout warnings are not a warning-free Xcode result.
- The freshly built release demo executable exited 0; it discards the simulation result, so this is an executable smoke check, not test-suite evidence.
- Both YAML files parsed, all three issue-intake scripts parsed under the v9 script parameters, and structural assertions verified all four matrix entries and matching build/test configurations. `git diff --check` passed.
- Full stable-Xcode tests, native iOS builds, and hosted workflow execution remain unverified. The RC test attempt was interrupted and is not counted as a pass. No commit, push, tag, issue assignment, or Project placement was performed.
- Sources: https://www.swift.org/blog/swift-6.4-released/ ; https://developer.apple.com/news/releases/?id=10152026a ; https://developer.apple.com/news/releases/?id=10192026g ; https://github.com/actions/checkout/releases ; https://github.com/actions/github-script/releases/tag/v9.0.0 ; https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md .

## 2026-08-23 Preset Correctness Follow-up

- [completed] Make V3 consume supplied rules for named presets and align canonical crossover periods.
- [completed] Apply next-market-open execution without final-candle force-closing to every standalone candle preset.
- [completed] Correct Supertrend, VWAP, EchoChannelPivot, LadderCompressionRelease, and parameter-validation semantics.
- [completed] Diversify bundled ticker return paths and replace tautological preset assertions with behavioral checks.
- [completed] Run focused and full verification, review the complete diff, and update GitHub issue #7.

### Review

- V3 now loads supplied entry/exit rules for all named policies and falls back to bundled rules only when neither side is stored; SMA/EMA crossovers use canonical 50/150 periods.
- Standalone candle strategies share next-market-open execution and preserve pending/open final-bar state without synthesizing a close.
- Supertrend, session VWAP, Echo reclaim, Ladder compression, invalid periods, VolatilitySnap warmup, and dataset diversity have focused regression coverage.
- Stable Xcode verification: 145 tests passed with 0 failures; production `swift build -c release` passed without warnings; `git diff --check` passed.

## 2026-08-21 Pending Exit Execution

- [completed] Reproduce the final-bar pending-exit trade inconsistency.
- [completed] Keep a final-bar exit pending without forming a completed trade.
- [completed] Verify the same exit completes at the next bar's market open.
- [completed] Run targeted and full Swift tests, then close GitHub issue #6.

### Review

- The regression test failed before the fix because a final-bar exit produced a synthetic completed trade.
- End-of-series mark-to-market finalization now applies only to `.position`; `.exit` remains pending until another bar executes it at that bar's open.
- The focused test and all 128 Swift package tests pass with stable Xcode.

## 2026-08-20 Swift 6.3 Compatibility Audit

- [completed] Inspect stable Swift 6.3.3 and Swift 6.4 beta diagnostics across package and Xcode builds.
- [completed] Implement only confirmed API, compiler error, and warning fixes.
- [completed] Re-run the full Swift test suite and relevant Xcode build validation.
- [completed] Record final evidence and close GitHub issue #5.

### Review

- No renamed or deprecated API migration was required. Strict Swift 6 mode exposed concurrency-safety diagnostics, resolved with checked `Sendable` conformances and lock-backed synchronization for the existing mutable hooks.
- Swift 6.3.3 configured and strict-mode tests passed all 127 tests. Swift 6.4 beta strict-mode tests also passed all 127 tests.
- The Xcode 27 beta Swift 6 build passed for an iPhone 16 Pro Max simulator destination. Xcode still emits its App Intents metadata-extraction warning despite no App Intents dependency and despite the documented disable build setting.

## 2026-05-02 Final Checkup

- [in-progress] Check current git/worktree state, branch context, and local task/release notes.
- [pending] Run package build/test verification from the live checkout.
- [pending] Review release/parity/manual gate status for any remaining blockers.
- [pending] Record the final checkup result in this file.

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

## 2026-08-23 BKPresets Rule Corrections

- [completed] Correct inverted Bollinger and moving-average crossover comparisons.
- [completed] Correct Fast Stochastic operands and custom-strategy policy identity.
- [completed] Make crossover policies require an actual two-bar crossing event.
- [completed] Add focused preset and v2/v3 parity regression coverage.
- [completed] Run targeted and full Swift tests, then update GitHub issue #7.

### Review

- Bollinger entries now require price at or below the lower band; Fast Stochastic compares `%K` with `%D`; custom presets retain `.customStrategy` identity.
- SMA and EMA crossover presets now use bullish entry and bearish exit comparisons, with shared strategy execution requiring a two-bar false-to-true transition.
- Verification: `swift test --filter BacktestingKitPresetRuleTests` passed 4 tests with 0 failures.
- Verification: `swift test` passed 132 tests with 0 failures.

## 2026-08-23 v0.2.3 Canonical Preset Correctness

- [x] Correct active built-in preset directions, operands, periods, and custom identity.
- [x] Make V3 prefer supplied rules for named policies while retaining legacy fallback behavior.
- [x] Add focused regression coverage for preset definitions and named canonical-rule execution.
- [x] Run targeted and full package tests.
- [x] Commit, publish, and verify the v0.2.3 tag; update GitHub issue #7.

### Review

- Named V3 policies now consume supplied canonical rules; legacy configurations without complete stored rules still use built-in presets.
- Corrected the active Bollinger, Fast Stochastic, SMA crossover, EMA crossover, and custom-policy definitions.
- Verification: `swift test --filter BacktestingKitPresetRuleTests` passed 2 tests with 0 failures.
- Verification: `swift test` passed 130 tests with 0 failures.
- Verification: `swift build -c release` completed successfully.
