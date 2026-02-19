import Foundation

/// Errors emitted by export helpers.
public enum BKExportError: LocalizedError, Equatable {
    case encodingFailed(String)
    case emptyData(String)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let message):
            return "Export encoding failed: \(message)"
        case .emptyData(let context):
            return "Export source is empty: \(context)"
        }
    }
}

/// Export helpers for stable JSON/CSV payload generation.
public enum BKExportTool {
    /// Encodes any `Encodable` payload to JSON.
    ///
    /// - Parameters:
    ///   - value: Encodable value.
    ///   - prettyPrinted: Whether to pretty-print output.
    /// - Returns: JSON string or typed export error.
    public static func toJSON<T: Encodable>(
        _ value: T,
        prettyPrinted: Bool = true
    ) -> Result<String, BKExportError> {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if prettyPrinted {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        } else {
            encoder.outputFormatting = [.sortedKeys]
        }
        do {
            let data = try encoder.encode(value)
            guard let output = String(data: data, encoding: .utf8) else {
                return .failure(.encodingFailed("Cannot encode UTF-8 output."))
            }
            return .success(output)
        } catch {
            return .failure(.encodingFailed(error.localizedDescription))
        }
    }

    /// Exports `BKTrade` values to CSV.
    ///
    /// - Parameter trades: Strategy trade entries.
    /// - Returns: CSV string or typed export error.
    public static func tradesToCSV(_ trades: [BKTrade]) -> Result<String, BKExportError> {
        guard !trades.isEmpty else {
            return .failure(.emptyData("trades"))
        }
        var lines: [String] = []
        lines.reserveCapacity(trades.count + 1)
        lines.append("direction,entryTime,entryPrice,exitTime,exitPrice,profit,profitPct,growth,riskPct,rmultiple,holdingPeriod,exitReason,stopPrice,profitTarget")

        for trade in trades {
            let fields: [String] = [
                trade.direction.rawValue,
                trade.entryTime.ISO8601Format(),
                String(trade.entryPrice),
                trade.exitTime.ISO8601Format(),
                String(trade.exitPrice),
                String(trade.profit),
                String(trade.profitPct),
                String(trade.growth),
                String(trade.riskPct),
                String(trade.rmultiple),
                String(trade.holdingPeriod),
                trade.exitReason,
                String(trade.stopPrice),
                String(trade.profitTarget),
            ]
            lines.append(fields.map(bkEscapeCSVValue).joined(separator: ","))
        }
        return .success(lines.joined(separator: "\n"))
    }
}

private func bkEscapeCSVValue(_ value: String) -> String {
    if value.contains(",") || value.contains("\"") || value.contains("\n") {
        return "\"\(value.replacing("\"", with: "\"\""))\""
    }
    return value
}
