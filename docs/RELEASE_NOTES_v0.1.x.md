# Release Notes - v0.1.x

Release date: TBD

## Highlights

- Additive portfolio orchestration for app and engine integrators with:
  - `BKEngine.PortfolioRequest`
  - `BKEngine.runPortfolio(...)`
  - `BKAppFacade.buildPortfolioCSVImportScreenState(...)`
  - `BKAppFacade.runConfirmedPortfolioCSVImport(...)`
- Portfolio export/report helpers for JSON, CSV, and Markdown outputs.
- Documentation/tutorial completion pass that gives the package one obvious markdown starting point, one clearer DocC starting point, and a more linear first-run story.

## Documentation Highlights

- `README.md` now acts as a lighter front door instead of trying to be the full tutorial.
- `docs/ONBOARDING.md` is the canonical markdown tutorial from build to app integration.
- `docs/GETTING_STARTED.md` is the shortest route from install to first success.
- `docs/CHOOSE_YOUR_SURFACE.md` now cleanly routes users between `BKAppFacade`, `BKEngine`, manager workflows, and tool helpers.
- DocC tutorial ordering now follows the same recommended sequence as the markdown beginner path.
- Tutorial examples now consistently use `summary.metrics.*` when inspecting `BKRunSummary`.

## Validation Status

- `swift build` ✅
- `swift build -c release` ✅
- `swift test` ✅
- `swift run BacktestingKitTrialDemo` ✅
- `bash tools/parity/run_parity.sh` ✅ when a local JS engine checkout is available

## Upgrade Notes

- Portfolio orchestration is additive and does not replace the existing single-instrument execution paths.
- The recommended beginner path is helper-first (`BKAppFacade`) and only drops to `BKEngine` when direct request-model control is needed.
- Compatibility aliases remain available through the `v0.1.x` release cycle to reduce upgrade friction while the canonical docs converge on the preferred names.

## Release Prep Notes

- This file is the prepared patch-track release summary and intentionally avoids locking the final `v0.1.x` tag too early.
- Tag creation, GitHub release publication, and contributor announcement remain explicit publish-time steps.
