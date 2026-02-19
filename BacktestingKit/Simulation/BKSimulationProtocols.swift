import Foundation

/// Defines the `BKV2SimulationDriving` contract used by BacktestingKit.
public protocol BKV2SimulationDriving {
    func simulateInstrument(
        instrumentID: String,
        config: BKV2.SimulationPolicyConfig,
        p1: Double,
        p2: Double,
        dateFormat: String,
        csvColumnMapping: BKCSVColumnMapping?
    ) async -> Result<(BKV2.SimulateConfigOutput, PositionStatus), BKEngineFailure>
}

/// Defines the `BKV3SimulationDriving` contract used by BacktestingKit.
public protocol BKV3SimulationDriving {
    func simulateInstrumentDetailed(
        _ instrument: BKV3_InstrumentInfo,
        p1: Double,
        p2: Double,
        dateFormat: String,
        executionOptions: BKSimulationExecutionOptions
    ) async -> Result<BKSimulationInstrumentReport, BKEngineFailure>
}

public extension BKV3SimulationDriving {
    func simulateInstrument(
        _ instrument: BKV3_InstrumentInfo,
        p1: Double = 5.0,
        p2: Double = 6.0,
        dateFormat: String = "yyyy-MM-dd"
    ) async -> Result<Void, BKEngineFailure> {
        let result = await simulateInstrumentDetailed(
            instrument,
            p1: p1,
            p2: p2,
            dateFormat: dateFormat,
            executionOptions: BKSimulationExecutionOptions(parserMode: .legacy)
        )
        switch result {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
}
