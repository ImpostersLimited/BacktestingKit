# Active Todo

## 2026-04-11 Xcode API Documentation Pass

- [completed] Review the current public API surface and existing documentation coverage.
- [completed] Identify public declarations that are missing Xcode doc comments.
- [completed] Add concise Xcode documentation comments to the full exposed API surface, including stored properties/constants.
- [completed] Verify documentation coverage with repo scans and a Swift package build/test pass.
- [completed] Record results and any follow-up gaps in the review notes below.

## Review

- Added Xcode Quick Help comments for previously undocumented public declarations and stored properties/constants across the exposed package surface.
- Verification scan: no undocumented public `class`/`struct`/`enum`/`protocol`/`actor`/`typealias`/`func`/`init`/`subscript`/`var`/`let` declarations remain in `BacktestingKit/`.
- Coverage now includes large model and facade/helper surfaces that were previously missing field-level Quick Help.
- Verification: `swift test` passed with 111 tests and 0 failures after the full documentation sweep.
