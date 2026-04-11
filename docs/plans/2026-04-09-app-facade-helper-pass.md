# 2026-04-09 App Facade Helper Pass

## Goal

Add a narrow app-facing facade so beginners and integrators can start from one public namespace without further expanding `BKEngine`.

## Constraints

- Additive only
- No behavior changes to existing `BKEngine`, manager, or tool helpers
- Delegate to existing public helpers instead of forking logic
- Keep the facade app-facing only; do not expose manager-only recipes from it

## Planned Surface

Create a static public namespace:

- `BKAppFacade.runPreset(dataset:preset:log:)`
- `BKAppFacade.runPresetCSV(...)`
- `BKAppFacade.preflightAndRunCSV(...)`
- `BKAppFacade.runScenario(config:)`
- `BKAppFacade.runV2ValidatedCSV(...)`
- `BKAppFacade.runV3ValidatedCSV(...)`
- `BKAppFacade.exportMarkdownSummary(...)`
- `BKAppFacade.exportRunBundle(...)`
- `BKAppFacade.compareRuns(...)`
- `BKAppFacade.assertEquivalent(...)`

Add facade-only orchestration helpers:

- `BKAppFacade.runPresetCSVAndExportMarkdown(...)`
- `BKAppFacade.runScenarioAndExportBundle(...)`

## Verification

- Focused facade tests
- Full `swift test`
- Docs scan to ensure the facade is discoverable from the beginner/app-integration paths
