# Parity Testing

Parity testing compares Swift outputs against JavaScript engine fixture outputs.

## Script

```bash
bash tools/parity/run_parity.sh
```

Optional JS engine path override:

```bash
JS_ENGINE_ROOT=../js-engine bash tools/parity/run_parity.sh
```

## JS Engine Resolution

The parity script looks for a local JavaScript engine checkout in this order:

1. `JS_ENGINE_ROOT`
2. `../js-engine`
3. `../algotrade-js-trial`
4. `./js-engine`

It requires this marker path to exist:

- `algotrade3/models/src/ATTechnicalIndicators.ts`

## What It Does

1. Builds the `BacktestingKit` framework.
2. Runs JavaScript fixture simulation (`tools/parity/js_runner.ts`).
3. Compiles/runs Swift fixture simulation (`tools/parity/swift_runner.swift`).
4. Compares JSON outputs with numeric tolerance checks.

## Success Criteria

- Script prints `PARITY_OK`
- Script prints `Parity check passed.`

## Environment Caveats

- Some macOS environments print noisy CoreSimulator/provisioning warnings during `xcodebuild`; these may be non-fatal.
- The script sets `CLANG_MODULE_CACHE_PATH` to `/tmp/backtestingkit-module-cache` to avoid restricted cache path failures.
- JS runner uses direct `node` execution from a relative JavaScript engine checkout.

## Contributor Setup (Private JS Parity)

Contributors can still build/test Swift without the JS engine checkout.

- Swift-only checks:
  - `swift build`
  - `swift test`
- Full parity checks:
  1. Clone JS engine in one of the auto-discovery paths.
  2. Install JS dependencies in that repo.
  3. Run `bash tools/parity/run_parity.sh` from this repo.

## Updating Fixtures

- Keep fixture changes intentional and reviewed.
- If parity changes, document the reason and expected delta before merging.
