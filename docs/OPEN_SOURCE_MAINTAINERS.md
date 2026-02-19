# Open Source Maintainer Guide

## Release Checklist

- [ ] Add and confirm `LICENSE`.
- [ ] Confirm `README.md` examples compile against current API.
- [ ] Run framework build in Debug and Release (`swift build`, `swift build -c release`).
- [ ] Run tests: `swift test`.
- [ ] Run parity (when local JS engine is available): `bash tools/parity/run_parity.sh`.
- [ ] Review breaking API changes and bump version.
- [ ] Tag release and publish changelog.

## Contribution Expectations

- Keep v2/v3 model shapes parity-safe.
- Do not introduce behavior changes in v2/v3 simulation paths without parity validation.
- Preserve strict parser behavior:
  - ISO8601 date-only/datetime strings.
  - Chronological row order.
- Add/update tests or fixture validation for non-trivial behavior changes.
- Require `ROADMAP.md` updates for every planned/implemented patch or feature:
  - add checklist item(s) when work starts
  - mark `[x]` when completed

## API Stability Strategy

Recommended approach:

- Treat model structs/enums used by v2/v3 parity paths as stable contracts.
- Additive changes preferred over mutating/removing existing fields.
- Gate risky changes behind new APIs instead of changing existing signatures.

## Suggested CI Pipeline

1. Swift build (Debug + Release).
2. Swift test.
3. Lint/static checks (if configured).
4. Parity run (only when local JS engine checkout is available).
4. Optional: doc generation and link validation.

## Security and Secrets

- Never commit API keys.
- Use environment variables for provider credentials.
- Redact sensitive payloads from logs and fixtures before publication.
