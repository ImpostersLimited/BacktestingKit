# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog:
https://keepachangelog.com/en/1.1.0/

## [Unreleased]

### Fixed
- V3 simulations now honor supplied rules for named policies and only fall back to built-in rules when persisted rules are absent.
- Corrected Bollinger, Fast Stochastic, SMA crossover, EMA crossover, and custom-policy preset definitions.

### Added
- Additive portfolio orchestration APIs for app and engine integrators:
  - `BKEngine.PortfolioRequest`
  - `BKEngine.runPortfolio(...)`
  - `BKAppFacade.buildPortfolioCSVImportScreenState(...)`
  - `BKAppFacade.runConfirmedPortfolioCSVImport(...)`
- Portfolio result/export helpers for stable JSON, CSV, and Markdown reporting without making export bundles the primary runtime contract.

### Changed
- Beginner-facing documentation now follows a single guided path:
  - `README.md` is the front door
  - `docs/ONBOARDING.md` is the canonical markdown tutorial
  - `docs/GETTING_STARTED.md` is the quick reference
  - `docs/CHOOSE_YOUR_SURFACE.md` is the routing guide
  - `docs/INDEX.md` is the documentation map
- DocC tutorial ordering now matches the markdown onboarding flow, with earlier first-success guidance and clearer app-integration routing.
- Onboarding/tutorial examples were updated to use current `BKRunSummary` metric access (`summary.metrics.*`) instead of stale `summary.result.*` examples.
- Compatibility aliases remain non-deprecated for the `v0.1.x` release cycle while canonical docs and examples route new integrations toward the preferred names.

## [0.2.5] - 2026-10-27

### Fixed
- CI release jobs now run tests in the release configuration.

### Changed
- Add debug/release CI coverage on stable Xcode 27.1 alongside the default macOS runner, with complete concurrency checking and compiler warnings treated as errors.
- Allow manual CI dispatch for verification before publication.
- Update GitHub Actions dependencies to `actions/checkout@v7` and `actions/github-script@v9`.
- Preserve the Swift 5.9 tools minimum, iOS 16/macOS 13 deployment targets, and existing public API.

## [0.1.0] - 2026-02-19

### Added
- Public Result-only runtime entrypoint contract for v2/v3 engine surfaces.
- Public presentation protocols for UI-ready payload and error summaries:
  - `BKUserPresentablePayload`
  - `BKUserPresentableError`
  - `BKResultPresentation`
  - `Result.uiPresentation`
- Quick Help doc strings across public API declarations for Xcode documentation parity.
- Open-source project metadata:
  - `LICENSE`
  - `CODE_OF_CONDUCT.md`
  - `SUPPORT.md`
  - issue and PR templates
  - CI workflow
  - `.gitignore`
- One-line end-to-end APIs:
  - `BKEngine.runV2(...)`
  - `BKEngine.runV3(...)`
- Quick demo APIs and bundled demo datasets:
  - `BKEngine.runDemo(...)`
  - `BKQuickDemo.runBundledSMACrossoverDemo(...)`
  - `BKDemoDataset` with 10 bundled symbols (NASDAQ + NYSE).
- Release documentation:
  - `docs/RELEASE_CHECKLIST.md`

### Changed
- CI now runs:
  - Swift Debug build
  - Swift Release build
  - Swift tests
  - Parity check only when local JS engine checkout is present.
- Parity tooling now resolves JS engine via relative paths/`JS_ENGINE_ROOT`, avoiding hardcoded absolute paths.
- Project docs updated for private/local JS parity contributor workflow.

### Removed
- Tracked parity-generated artifacts from source control:
  - `tools/parity/js_output.json`
  - `tools/parity/swift_output.json`
  - `tools/parity/swift_runner_bin`
