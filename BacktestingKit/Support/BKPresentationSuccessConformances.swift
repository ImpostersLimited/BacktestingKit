import Foundation

/// UI presentation mapping for per-instrument simulation reports.
extension BKSimulationInstrumentReport: BKUserPresentablePayload {
    public var uiTitle: String { "Instrument Simulation Report" }
    public var uiSummary: String {
        "\(instrumentID): \(configCountProcessed) configs, \(tradeCount) trades, \(riskPointCount) risk points"
    }
    public var uiDescription: String {
        "\(uiSummary), elapsed \(elapsedMS.formatted(.number.precision(.fractionLength(2)))) ms"
    }
    public var uiMetadata: [String: String] {
        [
            "instrumentID": instrumentID,
            "elapsedMS": String(elapsedMS),
            "configCountProcessed": String(configCountProcessed),
            "tradeCount": String(tradeCount),
            "riskPointCount": String(riskPointCount),
        ]
    }
}

/// UI presentation mapping for batch summary reports.
extension BKSimulationBatchReport: BKUserPresentablePayload {
    public var uiTitle: String { "Batch Simulation Report" }
    public var uiSummary: String {
        "total \(totalInstruments), succeeded \(succeeded), failed \(failed)"
    }
    public var uiDescription: String {
        "\(uiSummary), elapsed \(elapsedMS.formatted(.number.precision(.fractionLength(2)))) ms"
    }
    public var uiMetadata: [String: String] {
        [
            "totalInstruments": String(totalInstruments),
            "succeeded": String(succeeded),
            "failed": String(failed),
            "elapsedMS": String(elapsedMS),
            "memoryDeltaBytes": memoryDeltaBytes.map(String.init) ?? "n/a",
            "failureCount": String(failures.count),
        ]
    }
}

/// UI presentation mapping for batch detailed reports.
extension BKSimulationBatchDetailedReport: BKUserPresentablePayload {
    public var uiTitle: String { "Detailed Batch Simulation Report" }
    public var uiSummary: String { summary.uiSummary }
    public var uiDescription: String {
        "\(summary.uiDescription), instrumentReports=\(instrumentReports.count)"
    }
    public var uiMetadata: [String: String] {
        var details = summary.uiMetadata
        details["instrumentReports"] = String(instrumentReports.count)
        return details
    }
}

/// UI presentation mapping for offline demo summaries.
extension BKQuickDemoSummary: BKUserPresentablePayload {
    public var uiTitle: String { "Quick Demo Summary" }
    public var uiSummary: String {
        "\(symbol): \(barCount) bars, trades \(result.numTrades), return \((result.totalReturn * 100).formatted(.number.precision(.fractionLength(2))))%"
    }
    public var uiDescription: String {
        return "\(uiSummary), range \(dateRangeStart.ISO8601Format()) to \(dateRangeEnd.ISO8601Format())"
    }
    public var uiMetadata: [String: String] {
        return [
            "symbol": symbol,
            "barCount": String(barCount),
            "dateRangeStart": dateRangeStart.ISO8601Format(),
            "dateRangeEnd": dateRangeEnd.ISO8601Format(),
            "tradeCount": String(result.numTrades),
            "winRate": String(result.winRate),
            "totalReturn": String(result.totalReturn),
            "maxDrawdown": String(result.maxDrawdown),
        ]
    }
}

/// UI presentation mapping for v2 simulation output payloads.
extension BKV2.SimulateConfigOutput: BKUserPresentablePayload {
    public var uiTitle: String { "V2 Simulation Output" }
    public var uiSummary: String { "\(trades.count) trades generated" }
    public var uiDescription: String {
        "Policy \(config.policy.rawValue), trades \(trades.count), profit \(analysis.profit.formatted(.number.precision(.fractionLength(2))))"
    }
    public var uiMetadata: [String: String] {
        [
            "tradeCount": String(trades.count),
            "policy": config.policy.rawValue,
            "profit": String(analysis.profit),
            "profitPct": String(analysis.profitPct),
        ]
    }
}

/// UI presentation mapping for position status values.
extension PositionStatus: BKUserPresentablePayload {
    public var uiTitle: String { "Position Status" }
    public var uiSummary: String { rawValue }
    public var uiDescription: String { "Simulation ended with status '\(rawValue)'." }
    public var uiMetadata: [String: String] { ["status": rawValue] }
}
