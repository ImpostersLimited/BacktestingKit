// Candlestick.swift
// Core model for daily OHLCV data.

import Foundation

/// Represents `Candlestick` in the BacktestingKit public API.
public struct Candlestick: Equatable, Codable, Sendable {
    /// Date associated with this value.
    public let date: Date
    /// Open price for the bar.
    public let open: Double
    /// High price for the bar.
    public let high: Double
    /// Low price for the bar.
    public let low: Double
    /// Close price for the bar.
    public let close: Double
    /// Adjusted close price for the bar when available.
    public let adjustedClose: Double?
    /// Trading volume for the bar.
    public let volume: Double
    /// Technical indicator values keyed by indicator name.
    public var technicalIndicators: [String: Double]

    /// Creates a new instance.
    public init(
        date: Date,
        open: Double,
        high: Double,
        low: Double,
        close: Double,
        adjustedClose: Double? = nil,
        volume: Double,
        technicalIndicators: [String: Double] = [:]
    ) {
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.adjustedClose = adjustedClose
        self.volume = volume
        self.technicalIndicators = technicalIndicators
    }

    /// Parses a simple OHLCV CSV payload into candlesticks.
    ///
    /// - Parameters:
    ///   - csv: CSV text whose first row is the header.
    ///   - dateFormat: `DateFormatter` pattern used to decode the first column.
    /// - Returns: Parsed candlesticks. Rows that fail validation are skipped.
    public static func fromCSV(_ csv: String, dateFormat: String = "yyyy-MM-dd") -> [Candlestick] {
        var candlesticks: [Candlestick] = []
        let lines = csv.split(separator: "\n").map { String($0) }
        guard lines.count > 1 else { return [] }
        let headerColumns = lines[0]
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let adjustedCloseIndex = headerColumns.firstIndex(where: {
            $0 == "adjusted_close" || $0 == "adj_close" || $0 == "adjclose" || $0 == "adjusted close"
        })
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        for line in lines.dropFirst() { // Skip header
            let columns = line.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            guard columns.count >= 6,
                  let date = dateFormatter.date(from: columns[0]),
                  let open = Double(columns[1]),
                  let high = Double(columns[2]),
                  let low = Double(columns[3]),
                  let close = Double(columns[4]),
                  let volume = Double(columns[5]) else {
                continue
            }
            let adjustedClose: Double?
            if let adjustedCloseIndex, adjustedCloseIndex < columns.count {
                adjustedClose = Double(columns[adjustedCloseIndex])
            } else {
                adjustedClose = nil
            }
            candlesticks.append(
                Candlestick(
                    date: date,
                    open: open,
                    high: high,
                    low: low,
                    close: close,
                    adjustedClose: adjustedClose,
                    volume: volume
                )
            )
        }
        return candlesticks
    }
}

extension Candlestick: BKPriceBarRepresentable {}
