# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog:
https://keepachangelog.com/en/1.1.0/

## [Unreleased]

### Planned
- Keep compatibility aliases non-deprecated for the v0.1.x release cycle.

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
