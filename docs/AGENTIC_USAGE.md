# Agentic Tools Integration Guide

This guide explains how to operate BacktestingKit with AI/agentic tooling (Codex-style agents, CI bots, scripted assistants).

## Core Constraints for Agents

Agents must keep these non-negotiable rules:

1. Preserve v2/v3 parity model shapes.
2. Do not change public return semantics from `Result`.
3. Keep CSV parsing strict behavior (ISO8601 + chronological order).
4. Avoid force unwrap/force try and avoid legacy ObjC-style APIs when Swift-native options exist.

## Standard Agent Runbook

Use this sequence for every non-trivial change:

1. Read docs:
   - `docs/MODELS_AND_PARITY.md`
   - `docs/API_REFERENCE.md`
   - `docs/TOOLS.md`
2. Make change in smallest isolated file set.
3. Run validation:
   - `swift test`
   - `swift build -c release` (for release-impacting changes)
4. Run parity check when behavior might change:
   - `bash tools/parity/run_parity.sh`
5. Summarize:
   - what changed
   - why safe for parity
   - test/parity evidence

## Prompt Template for Agentic Tools

Use this base prompt with any coding agent:

```text
Task: <describe change>
Constraints:
- Keep v2/v3 output shape parity unchanged.
- Keep all public APIs Result-based.
- Do not modify model contracts.
- Use modern Swift APIs only.
- Add/update tests and docs.
Validation required:
- swift test
- parity check if simulation behavior is affected
Deliver:
- changed files
- reasoning
- pass/fail evidence
```

## Agent-Safe Extension Points

Prefer agent changes in these areas first:

- `BacktestingKit/Tools/*` (additive helper tooling)
- `docs/*` (documentation)
- `Tests/BacktestingKitTests/*` (coverage)

Higher-risk areas that require parity proof:

- `BacktestingKit/Simulation/V2/*`
- `BacktestingKit/Simulation/V3/*`
- `BacktestingKit/Analysis/*`
- `BacktestingKit/Engine/*` (entrypoints / return surfaces)

## Built-in Tools Agents Should Use

- `BKValidationTool`
  - preflight requests and CSV before execution
- `BKDiagnosticsCollector`
  - emit progress and failure lifecycle events
- `BKBenchmarkTool`
  - compare latency/memory before vs after refactors
- `BKParityTool`
  - compare numeric outputs with explicit tolerance
- `BKExportTool`
  - persist artifacts for reproducibility and review

## CI / Automation Recommendations

For PR automation agents:

1. Run `swift test`.
2. Run parity script for simulation-related changes.
3. Fail PR when:
   - tests fail
   - parity fails
   - public API drift is detected without docs update
4. Attach:
   - failing tests or mismatches
   - exact files requiring review

## Review Checklist for Agent-Generated Changes

- Public API docs updated?
- Xcode Quick Help present for new public symbols?
- New behavior covered by tests?
- No parity or model-shape regressions?
- No added unsafe patterns (`try!`, force unwrap, deprecated APIs)?

## Related Docs

- `docs/TOOLS.md`
- `docs/PARITY_TESTING.md`
- `docs/RELEASE_CHECKLIST.md`
