import Foundation

/// UI presentation mapping for per-instrument simulation reports.
extension BKSimulationInstrumentReport: BKUserPresentablePayload {
    /// Short title used when presenting this value to people.
    public var uiTitle: String { "Instrument Simulation Report" }
    /// One-line summary used when presenting this value to people.
    public var uiSummary: String {
        "\(instrumentID): \(configCountProcessed) configs, \(tradeCount) trades, \(riskPointCount) risk points"
    }
    /// Detailed description used when presenting this value to people.
    public var uiDescription: String {
        "\(uiSummary), elapsed \(elapsedMS.formatted(.number.precision(.fractionLength(2)))) ms"
    }
    /// Structured metadata associated with this value.
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
    /// Short title used when presenting this value to people.
    public var uiTitle: String { "Batch Simulation Report" }
    /// One-line summary used when presenting this value to people.
    public var uiSummary: String {
        "total \(totalInstruments), succeeded \(succeeded), failed \(failed)"
    }
    /// Detailed description used when presenting this value to people.
    public var uiDescription: String {
        "\(uiSummary), elapsed \(elapsedMS.formatted(.number.precision(.fractionLength(2)))) ms"
    }
    /// Structured metadata associated with this value.
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
    /// Short title used when presenting this value to people.
    public var uiTitle: String { "Detailed Batch Simulation Report" }
    /// One-line summary used when presenting this value to people.
    public var uiSummary: String { summary.uiSummary }
    /// Detailed description used when presenting this value to people.
    public var uiDescription: String {
        "\(summary.uiDescription), instrumentReports=\(instrumentReports.count)"
    }
    /// Structured metadata associated with this value.
    public var uiMetadata: [String: String] {
        var details = summary.uiMetadata
        details["instrumentReports"] = String(instrumentReports.count)
        return details
    }
}

/// UI presentation mapping for offline demo summaries.
extension BKQuickDemoSummary: BKUserPresentablePayload {
    /// Short title used when presenting this value to people.
    public var uiTitle: String { "Quick Demo Summary" }
    /// One-line summary used when presenting this value to people.
    public var uiSummary: String {
        "\(symbol): \(barCount) bars, trades \(result.numTrades), return \((result.totalReturn * 100).formatted(.number.precision(.fractionLength(2))))%"
    }
    /// Detailed description used when presenting this value to people.
    public var uiDescription: String {
        return "\(uiSummary), range \(dateRangeStart.ISO8601Format()) to \(dateRangeEnd.ISO8601Format())"
    }
    /// Structured metadata associated with this value.
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
    /// Short title used when presenting this value to people.
    public var uiTitle: String { "V2 Simulation Output" }
    /// One-line summary used when presenting this value to people.
    public var uiSummary: String { "\(trades.count) trades generated" }
    /// Detailed description used when presenting this value to people.
    public var uiDescription: String {
        "Policy \(config.policy.rawValue), trades \(trades.count), profit \(analysis.profit.formatted(.number.precision(.fractionLength(2))))"
    }
    /// Structured metadata associated with this value.
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
    /// Short title used when presenting this value to people.
    public var uiTitle: String { "Position Status" }
    /// One-line summary used when presenting this value to people.
    public var uiSummary: String { rawValue }
    /// Detailed description used when presenting this value to people.
    public var uiDescription: String { "Simulation ended with status '\(rawValue)'." }
    /// Structured metadata associated with this value.
    public var uiMetadata: [String: String] { ["status": rawValue] }
}
