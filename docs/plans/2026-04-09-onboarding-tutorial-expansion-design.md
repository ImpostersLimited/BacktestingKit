# Onboarding Tutorial Expansion Design

Date: 2026-04-09

## Goal

Add beginner-friendly onboarding docs for BacktestingKit that also transition cleanly into real app integration.

## Approved Direction

Use a hybrid onboarding structure:

1. One linear onboarding guide for a user's first successful run with the package.
2. A small sequence of focused onboarding tutorials for follow-on learning and app integration.

This keeps the beginner path opinionated while still giving app developers reusable entrypoints after the first success.

## Coverage Targets

The onboarding set should answer these questions in order:

1. How do I build the package and prove it works locally?
2. How do I run my first backtest without wiring external data?
3. How do I run from inline CSV when I already have data?
4. How do I integrate the canonical `BKEngine` APIs into an app?
5. Where do I go next for helper workflows, manager workflows, and tool workflows?

## Planned Outputs

### Markdown onboarding

- Add `docs/ONBOARDING.md` as the linear beginner path.
- Keep it short and success-oriented:
  - build the package
  - run the bundled demo
  - run inline CSV
  - move into canonical app integration with `BKEngine`
  - branch to deeper guides

### DocC onboarding

- Add an onboarding chapter to `BacktestingKitTutorials.tutorial`.
- Add `BKPackageOnboardingTutorial.tutorial` as the top-level first-run tutorial.
- Add `BKInstallAndFirstSuccessTutorial.tutorial` for the minimal “clone, build, run demo” path.
- Add `BKAppIntegrationTutorial.tutorial` for the first canonical app integration walkthrough.
- Reuse existing deeper tutorials as follow-on material instead of duplicating manager/tool/helper coverage.

## Navigation Changes

Update these entrypoints so onboarding is obvious:

- `README.md`
- `docs/INDEX.md`
- `docs/GETTING_STARTED.md`
- `docs/PACKAGE_USAGE_GUIDE.md`
- `BacktestingKitTutorials.tutorial`

## Constraints

- Additive docs/tutorial changes only.
- No API changes.
- Examples must reflect the current `Result`-based helper APIs and current provider signatures.
- Avoid duplicating full package reference material inside onboarding docs; use onboarding docs to route users to the right next guide.

## Verification

- Scan onboarding docs for stale API patterns.
- Confirm the new onboarding files are linked from the main doc entrypoints.
- Run `swift test` as a regression guard after doc edits.
