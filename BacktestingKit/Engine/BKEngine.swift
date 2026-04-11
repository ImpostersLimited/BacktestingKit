import Foundation

/// Canonical entrypoint surface for BacktestingKit.
/// Use this type as the single source of truth for v2/v3 runs and demos.
public enum BKEngine {
    /// Provides the `V2Request` typealias for BacktestingKit interoperability.
    public typealias V2Request = BKEngineOneLiner.BKV2Request
    /// Provides the `V3Request` typealias for BacktestingKit interoperability.
    public typealias V3Request = BKEngineOneLiner.BKV3Request

    /// Factory used to build the v3 simulation driver behind `runV3`.
    public static var makeV3Driver: @Sendable (_ dataStore: BKV3DataStore, _ csvProvider: BKRawCsvProvider) -> any BKV3SimulationDriving {
        get { BKEngineOneLiner.makeV3Driver }
        set { BKEngineOneLiner.makeV3Driver = newValue }
    }

    /// Factory used to build the v2 simulation driver behind `runV2`.
    public static var makeV2Driver: @Sendable (_ csvProvider: BKRawCsvProvider) -> any BKV2SimulationDriving {
        get { BKEngineOneLiner.makeV2Driver }
        set { BKEngineOneLiner.makeV2Driver = newValue }
    }

    /// Runs a v3 request through the configured simulation driver.
    public static func runV3(_ request: V3Request) async -> Result<BKSimulationInstrumentReport, BKEngineFailure> {
        await BKEngineOneLiner.runBKV3(request)
    }

    /// Runs a v2 request through the configured simulation driver.
    public static func runV2(_ request: V2Request) async -> Result<(BKV2.SimulateConfigOutput, PositionStatus), BKEngineFailure> {
        await BKEngineOneLiner.runBKV2(request)
    }

    /// Executes the package's bundled SMA crossover demo workflow.
    public static func runDemo(
        dataset: BKQuickDemoDataset = .aapl,
        csv: String? = nil,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> Result<BKQuickDemoSummary, Error> {
        BKQuickDemo.runBundledSMACrossoverDemo(
            dataset: dataset,
            csv: csv,
            log: log
        )
    }
}
