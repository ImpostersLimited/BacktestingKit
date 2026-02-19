# Release Notes - v0.1.0

Release date: 2026-02-19

## Highlights

- First public release of BacktestingKit.
- Result-only runtime execution APIs for both v2/v3 entrypoints.
- Strict CSV ingestion with ISO8601 parsing, chronological-order enforcement, and custom OHLCV mapping.
- Provider-driven data ingestion (`BKRawCsvProvider`) with optional AlphaVantage provider + caching wrappers.
- Expanded strategy and metric catalog including agentic presets and advanced risk/performance metrics.
- Public UI presentation contracts for standardized success/error rendering:
  - `BKUserPresentablePayload`
  - `BKUserPresentableError`
  - `BKResultPresentation`
  - `Result.uiPresentation`
- Quick Help documentation pass across public API declarations.

## Validation status

- `swift build` ✅
- `swift build -c release` ✅
- `swift test` ✅
- `swift run BacktestingKitTrialDemo` ✅
- `bash tools/parity/run_parity.sh` ✅

## Upgrade notes

- Public runtime APIs use `Result` (not `throws`) for engine execution flows.
- README snippets were updated to use Result-based handling.
- No breaking parity changes in v2/v3 model semantics; release is additive around API ergonomics and documentation.

## Known constraints

- Parity checks require local access to the JavaScript engine checkout.
- Demo datasets are bundled for offline trials and intended for smoke/UX onboarding, not production signal quality assessment.
