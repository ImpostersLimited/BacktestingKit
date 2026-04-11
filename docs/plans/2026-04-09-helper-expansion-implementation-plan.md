# Helper Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add strictly additive helper APIs across `BKEngine`, `BacktestingKitManager`, and `BK*Tool` so app developers and smoke-test/demo users can complete common workflows with less boilerplate.

**Architecture:** Introduce focused helper model files plus additive workflow/helper extensions that delegate into the existing engine, manager, parser, and tool implementations. Keep `BKEngine` as the canonical top-level surface, use `BacktestingKitManager` for reusable indicator/strategy/report composition, and use `BK*Tool` for operational workflows such as validation, diagnostics, export, and scenario readiness.

**Tech Stack:** Swift 5.9, Swift Package Manager, XCTest, existing `BacktestingKit` targets and resources.

---

### Task 1: Add Shared Helper Result Models

**Files:**
- Create: `BacktestingKit/Engine/BKEngineHelperModels.swift`
- Create: `BacktestingKit/Engine/BKManagerHelperModels.swift`
- Create: `BacktestingKit/Tools/BKToolHelperModels.swift`
- Test: `Tests/BacktestingKitTests/BacktestingKitEngineTests.swift`
- Test: `Tests/BacktestingKitTests/BacktestingKitToolsTests.swift`

- [ ] **Step 1: Define the helper model families**

Add focused additive public types such as:

```swift
public struct BKRunHeadlineMetrics: Codable, Equatable {
    public var tradeCount: Int
    public var winRate: Double
    public var totalReturn: Double
    public var annualizedReturn: Double
    public var maxDrawdown: Double
    public var sharpeRatio: Double
    public var profitFactor: Double
}

public struct BKRunSummary: Codable, Equatable {
    public var symbol: String
    public var barCount: Int
    public var metrics: BKRunHeadlineMetrics
}
```

- [ ] **Step 2: Keep model responsibilities separated**

Use:
- `BKEngineHelperModels.swift` for app-facing workflow summaries
- `BKManagerHelperModels.swift` for manager-level bundles like indicator/report packages
- `BKToolHelperModels.swift` for validation/export/diagnostics workflow reports

- [ ] **Step 3: Add initial shape tests**

Add compilation/behavior coverage in existing test files for:
- Codable round-trips where helpful
- Equatable semantics
- headline metric extraction expectations

- [ ] **Step 4: Run targeted tests**

Run:

```bash
swift test --filter BacktestingKitEngineTests
swift test --filter BacktestingKitToolsTests
```

Expected: both test groups pass.

- [ ] **Step 5: Commit**

```bash
git add BacktestingKit/Engine/BKEngineHelperModels.swift BacktestingKit/Engine/BKManagerHelperModels.swift BacktestingKit/Tools/BKToolHelperModels.swift Tests/BacktestingKitTests/BacktestingKitEngineTests.swift Tests/BacktestingKitTests/BacktestingKitToolsTests.swift
git commit -m "feat: add helper result models"
```

### Task 2: Add App-Facing `BKEngine` Workflow Helpers

**Files:**
- Modify: `BacktestingKit/Engine/BKEngine.swift`
- Modify: `BacktestingKit/Engine/BKEngineOneLiner.swift`
- Create: `BacktestingKit/Engine/BKEngineWorkflowHelpers.swift`
- Modify: `BacktestingKit/Data/BKDataProviders.swift`
- Test: `Tests/BacktestingKitTests/BacktestingKitEngineTests.swift`

- [ ] **Step 1: Add an inline/raw CSV provider helper if one is not already public**

If the package lacks a public closure-backed provider suitable for inline CSV, add an additive helper in `BKDataProviders.swift`:

```swift
public struct BKInlineCsvProvider: BKRawCsvProvider {
    public let csv: String
    public init(csv: String) { self.csv = csv }

    public func getRawCsv(ticker: String, p1: Double, p2: Double) async -> Result<String, Error> {
        .success(csv)
    }
}
```

- [ ] **Step 2: Add summary-building helpers that derive from existing results**

In `BKEngineWorkflowHelpers.swift`, add additive helpers like:

```swift
public extension BKEngine {
    static func summarize(
        symbol: String,
        bars: [BKBar],
        result: BacktestResult
    ) -> BKRunSummary
}
```

These helpers should only derive presentation-friendly output from existing engine results.

- [ ] **Step 3: Add CSV-backed run helpers**

Expose additive convenience entrypoints:

```swift
public extension BKEngine {
    static func runDemoCSV(
        symbol: String,
        csv: String,
        fast: Int = 5,
        slow: Int = 20,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> Result<BKQuickDemoSummary, Error>
}
```

And async v2/v3-oriented wrappers where the helper meaningfully reduces request boilerplate without re-implementing driver logic.

- [ ] **Step 4: Add preset-oriented engine helpers**

Add one or two constrained preset helpers optimized for onboarding:
- run bundled dataset with a named preset
- run inline CSV with a canonical preset path

Keep these thin wrappers that build the current request/config types and delegate into the existing engine behavior.

- [ ] **Step 5: Add tests for success and typed failure**

Extend `BacktestingKitEngineTests.swift` to cover:
- summary generation
- CSV-backed workflow success
- empty/invalid CSV failure path
- helper parity with current `runDemo`

- [ ] **Step 6: Run targeted tests**

Run:

```bash
swift test --filter BacktestingKitOneLinerTests
swift test --filter BacktestingKitCSVTests
```

Expected: existing and new engine helper tests pass.

- [ ] **Step 7: Commit**

```bash
git add BacktestingKit/Engine/BKEngine.swift BacktestingKit/Engine/BKEngineOneLiner.swift BacktestingKit/Engine/BKEngineWorkflowHelpers.swift BacktestingKit/Data/BKDataProviders.swift Tests/BacktestingKitTests/BacktestingKitEngineTests.swift
git commit -m "feat: add engine workflow helpers"
```

### Task 3: Expand Bundled Demo and Smoke-Test Helpers

**Files:**
- Modify: `BacktestingKit/Engine/BKQuickDemo.swift`
- Create: `BacktestingKit/Engine/BKDemoWorkflowHelpers.swift`
- Test: `Tests/BacktestingKitTests/BacktestingKitDemoWorkflowTests.swift`

- [ ] **Step 1: Add reusable bundled CSV loading helpers**

Refactor `BKQuickDemo.swift` just enough to expose internal reusable pieces for:
- bundled CSV loading
- bar parsing
- summary generation

Do not change current public behavior.

- [ ] **Step 2: Add additional bundled dataset workflows**

Create additive helpers such as:

```swift
public extension BKQuickDemo {
    static func runBundledPresetDemo(
        dataset: BKQuickDemoDataset,
        preset: SimulationPolicy,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> Result<BKRunSummary, Error>
}
```

And a deterministic smoke helper:

```swift
public static func runBundledSmokeMatrix(
    datasets: [BKQuickDemoDataset] = BKQuickDemoDataset.allCases
) -> Result<[BKRunSummary], Error>
```

- [ ] **Step 3: Add a dedicated workflow test file**

Create `BacktestingKitDemoWorkflowTests.swift` covering:
- bundled dataset loading
- deterministic smoke matrix behavior
- summary contents for at least one known dataset

- [ ] **Step 4: Run targeted tests**

Run:

```bash
swift test --filter BacktestingKitDemoWorkflowTests
```

Expected: all new demo workflow tests pass.

- [ ] **Step 5: Commit**

```bash
git add BacktestingKit/Engine/BKQuickDemo.swift BacktestingKit/Engine/BKDemoWorkflowHelpers.swift Tests/BacktestingKitTests/BacktestingKitDemoWorkflowTests.swift
git commit -m "feat: add bundled demo workflow helpers"
```

### Task 4: Add `BacktestingKitManager` Mid-Level Helper Bundles

**Files:**
- Modify: `BacktestingKit/Engine/BacktestingKit.swift`
- Create: `BacktestingKit/Engine/BKManagerWorkflowHelpers.swift`
- Test: `Tests/BacktestingKitTests/BacktestingKitManagerHelperTests.swift`

- [ ] **Step 1: Add indicator bundle helpers**

Expose additive helpers that compose existing manager methods:

```swift
public extension BacktestingKitManager {
    func applyTrendIndicatorBundle(
        candles: [Candlestick],
        smaPeriods: [Int],
        emaPeriods: [Int],
        keyNamespace: String
    ) -> [Candlestick]
}
```

Do the same for momentum and volatility bundles where the composition is clear and deterministic.

- [ ] **Step 2: Add result-to-report convenience helpers**

Add helpers like:

```swift
public extension BacktestingKitManager {
    func buildHeadlineMetrics(from result: BacktestResult) -> BKRunHeadlineMetrics
}
```

And one higher-level packaging helper:

```swift
func buildSummary(
    symbol: String,
    candles: [Candlestick],
    result: BacktestResult
) -> BKRunSummary
```

- [ ] **Step 3: Add a small number of strategy boilerplate reducers**

Add focused helpers that reduce repeated setup rather than multiplying preset-specific methods:
- helper for SMA crossover summary execution
- helper for EMA crossover summary execution
- helper that runs a closure-based strategy then packages summary + metrics

- [ ] **Step 4: Create dedicated manager helper tests**

Create `BacktestingKitManagerHelperTests.swift` to cover:
- indicator bundle key population
- summary/report correctness
- simple strategy workflow helper behavior

- [ ] **Step 5: Run targeted tests**

Run:

```bash
swift test --filter BacktestingKitManagerHelperTests
```

Expected: all new manager helper tests pass.

- [ ] **Step 6: Commit**

```bash
git add BacktestingKit/Engine/BacktestingKit.swift BacktestingKit/Engine/BKManagerWorkflowHelpers.swift Tests/BacktestingKitTests/BacktestingKitManagerHelperTests.swift
git commit -m "feat: add manager helper bundles"
```

### Task 5: Add Tool-Level Operational Workflow Helpers

**Files:**
- Modify: `BacktestingKit/Tools/BKValidationTool.swift`
- Modify: `BacktestingKit/Tools/BKExportTool.swift`
- Modify: `BacktestingKit/Tools/BKDiagnosticsTool.swift`
- Modify: `BacktestingKit/Tools/BKScenarioTool.swift`
- Create: `BacktestingKit/Tools/BKToolWorkflowHelpers.swift`
- Test: `Tests/BacktestingKitTests/BacktestingKitToolsTests.swift`

- [ ] **Step 1: Add CSV preflight workflow helpers**

Expand validation into a richer additive workflow:

```swift
public extension BKValidationTool {
    static func preflightCSV(
        _ csv: String,
        columnMapping: BKCSVColumnMapping? = nil
    ) -> BKCSVPreflightReport
}
```

This report should combine:
- validation status
- parsed row count when valid
- date range when valid
- structured issues when invalid

- [ ] **Step 2: Add diagnostics snapshot reporting**

Add additive helpers on the collector or in `BKToolWorkflowHelpers.swift`:

```swift
public func summarizedSnapshot() async -> BKDiagnosticsSnapshotReport
```

This should package:
- event count
- first/last timestamps
- stage counts
- last error/failure-like event if present

- [ ] **Step 3: Add export bundle helpers**

Add grouped export helpers such as:

```swift
public extension BKExportTool {
    static func exportRunBundle(
        summary: BKRunSummary,
        trades: [BKTrade],
        diagnostics: BKDiagnosticsSnapshotReport?
    ) -> Result<BKExportBundle, BKExportError>
}
```

Where `BKExportBundle` contains multiple string payloads, for example JSON plus CSV.

- [ ] **Step 4: Add scenario readiness helpers**

Use `BKScenarioTool` to support better smoke workflows:
- deterministic scenario summary helper
- scenario run + export bundle helper
- scenario validation helper for config sanity

- [ ] **Step 5: Extend tool tests**

Expand `BacktestingKitToolsTests.swift` to cover:
- preflight report success/failure
- diagnostics summary
- export bundle generation
- deterministic scenario summary behavior

- [ ] **Step 6: Run targeted tests**

Run:

```bash
swift test --filter BacktestingKitToolsTests
```

Expected: all existing and new tool tests pass.

- [ ] **Step 7: Commit**

```bash
git add BacktestingKit/Tools/BKValidationTool.swift BacktestingKit/Tools/BKExportTool.swift BacktestingKit/Tools/BKDiagnosticsTool.swift BacktestingKit/Tools/BKScenarioTool.swift BacktestingKit/Tools/BKToolWorkflowHelpers.swift Tests/BacktestingKitTests/BacktestingKitToolsTests.swift
git commit -m "feat: add tool workflow helpers"
```

### Task 6: Update API Docs and Getting Started Paths

**Files:**
- Modify: `README.md`
- Modify: `docs/API_REFERENCE.md`
- Modify: `docs/GETTING_STARTED.md`
- Modify: `docs/AGENTIC_USAGE.md`
- Optional create: `docs/HELPER_WORKFLOWS.md`

- [ ] **Step 1: Add “fastest path” examples for app developers**

Update `README.md` and `docs/GETTING_STARTED.md` with:
- a CSV-backed quick run example
- a bundled demo/smoke workflow example
- a summary/report helper example

- [ ] **Step 2: Document the new public helper families**

Update `docs/API_REFERENCE.md` so the helper expansion is grouped by:
- engine workflow helpers
- manager helper bundles
- tool workflow helpers

- [ ] **Step 3: Update agentic/demo usage docs**

Add examples to `docs/AGENTIC_USAGE.md` showing how smoke-test and diagnostics helpers fit into agentic flows.

- [ ] **Step 4: Run documentation sanity checks**

Run:

```bash
rg -n "runDemoCSV|runBundledPresetDemo|preflightCSV|applyTrendIndicatorBundle|exportRunBundle" README.md docs BacktestingKit
```

Expected: each documented helper exists in code and appears in the expected docs.

- [ ] **Step 5: Commit**

```bash
git add README.md docs/API_REFERENCE.md docs/GETTING_STARTED.md docs/AGENTIC_USAGE.md docs/HELPER_WORKFLOWS.md
git commit -m "docs: add helper workflow documentation"
```

### Task 7: Run Full Verification Before Completion

**Files:**
- Verify: `Package.swift`
- Verify: `Tests/BacktestingKitTests/*.swift`

- [ ] **Step 1: Run the full test suite**

Run:

```bash
swift test
```

Expected: full package test suite passes.

- [ ] **Step 2: Run the trial demo executable**

Run:

```bash
swift run BacktestingKitTrialDemo
```

Expected: demo completes and prints a stable summary without runtime failures.

- [ ] **Step 3: Run the parity script if environment is available**

Run:

```bash
bash tools/parity/run_parity.sh
```

Expected: `PARITY_OK` and `Parity check passed.`

If the JS parity environment is not present, record that explicitly in the review notes rather than silently skipping it.

- [ ] **Step 4: Review public API impact**

Run:

```bash
rg -n "public (enum|struct|class|protocol|func|var|typealias)" BacktestingKit/Engine BacktestingKit/Tools BacktestingKit/Engine/BacktestingKit.swift
```

Expected: only additive public declarations were introduced; no existing declarations were removed.

- [ ] **Step 5: Final commit**

```bash
git add BacktestingKit README.md docs Tests
git commit -m "feat: expand helper workflows across engine manager and tools"
```

## Review Notes Template

Add this section to `tasks/todo.md` as implementation progresses:

```markdown
## Review

- Scope delivered:
- Tests run:
- Demo verification:
- Parity verification:
- Public API changes:
- Known follow-ups:
```
