import Foundation

public extension Result where Success == (BKV2.SimulateConfigOutput, PositionStatus), Failure == BKEngineFailure {
    /// Produces a unified UI presentation for v2 one-liner results while preserving tuple return semantics.
    var uiPresentation: BKResultPresentation {
        switch self {
        case .success(let output):
            let summary = output.0
            let status = output.1
            return BKResultPresentation(
                title: "V2 Simulation Result",
                summary: "\(summary.trades.count) trades, status \(status.rawValue)",
                description: "Policy \(summary.config.policy.rawValue), trades \(summary.trades.count), status \(status.rawValue)",
                metadata: [
                    "status": status.rawValue,
                    "tradeCount": String(summary.trades.count),
                    "policy": summary.config.policy.rawValue,
                    "profit": String(summary.analysis.profit),
                ],
                isError: false
            )
        case .failure(let failure):
            return BKResultPresentation(
                title: failure.uiTitle,
                summary: failure.uiSummary,
                description: failure.uiDescription,
                metadata: failure.uiMetadata,
                isError: true,
                errorCode: failure.uiErrorCode,
                isRetryable: failure.uiRetryable
            )
        }
    }
}
