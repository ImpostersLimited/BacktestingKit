# Contributing

Thanks for contributing to BacktestingKit.

## Development setup

```bash
swift --version
swift build
swift test
```

For parity-sensitive changes, also run:

```bash
bash tools/parity/run_parity.sh
```

## Guardrails

- Keep v2/v3 model contracts parity-safe.
- Do not break simulation semantics without explicit justification.
- Preserve strict CSV parsing behavior:
  - ISO8601 date input.
  - Chronological data enforcement.
- Prefer additive API changes over breaking changes.

## Pull requests

Please include:

- Problem statement.
- Behavioral changes and tradeoffs.
- Validation output (`swift build`, `swift test`, parity when applicable).
- Documentation updates when behavior or APIs changed.
- `ROADMAP.md` update:
  - add new checklist item(s) for planned/implemented work
  - mark completed items as `[x]`

Use `.github/pull_request_template.md`.

## Code of conduct

By participating, you agree to follow `CODE_OF_CONDUCT.md`.
