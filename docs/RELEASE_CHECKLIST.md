# Release Checklist

## Pre-release Validation

- [x] `swift build`
- [x] `swift build -c release`
- [x] `swift test`
- [x] `swift run BacktestingKitTrialDemo`
- [x] `bash tools/parity/run_parity.sh` (if local JS engine checkout is present)

## API and Behavior Review

- [x] Confirm v2/v3 model contracts are unchanged or additive only.
- [x] Confirm parser behavior remains strict for ISO8601 + chronological ordering.
- [x] Confirm canonical entrypoint APIs (`BKEngine.runV2`, `BKEngine.runV3`, `BKEngine.runDemo`) still compile from README snippets.

## Packaging and Metadata

- [x] `LICENSE`, `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md` are updated.
- [x] No generated artifacts are tracked (`tools/parity/*_output.json`, `tools/parity/swift_runner_bin`, `.build/`).
- [x] `Package.swift` products/targets/resources are correct.

## Publish

- [ ] Create release tag (`vX.Y.Z`).
- [ ] Publish release notes from `CHANGELOG.md`.
- [ ] Announce parity baseline and required JS engine revision for contributors.
