import Foundation

/// Canonical entrypoint surface for BacktestingKit.
/// Use this type as the single source of truth for v2/v3 runs and demos.
public enum BKEngine {
    /// Provides the `V2Request` typealias for BacktestingKit interoperability.
    public typealias V2Request = BKEngineOneLiner.BKV2Request
    /// Provides the `V3Request` typealias for BacktestingKit interoperability.
    public typealias V3Request = BKEngineOneLiner.BKV3Request

    public static var makeV3Driver: @Sendable (_ dataStore: BKV3DataStore, _ csvProvider: BKRawCsvProvider) -> any BKV3SimulationDriving {
        get { BKEngineOneLiner.makeV3Driver }
        set { BKEngineOneLiner.makeV3Driver = newValue }
    }

    public static var makeV2Driver: @Sendable (_ csvProvider: BKRawCsvProvider) -> any BKV2SimulationDriving {
        get { BKEngineOneLiner.makeV2Driver }
        set { BKEngineOneLiner.makeV2Driver = newValue }
    }

    public static func runV3(_ request: V3Request) async -> Result<BKSimulationInstrumentReport, BKEngineFailure> {
        await BKEngineOneLiner.runBKV3(request)
    }

    public static func runV2(_ request: V2Request) async -> Result<(BKV2.SimulateConfigOutput, PositionStatus), BKEngineFailure> {
        await BKEngineOneLiner.runBKV2(request)
    }

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
