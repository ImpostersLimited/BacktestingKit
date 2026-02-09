// Candlestick.swift
// Core model for daily OHLCV data.

import Foundation

public struct Candlestick: Equatable, Codable {
    public let date: Date
    public let open: Double
    public let high: Double
    public let low: Double
    public let close: Double
    public let volume: Double
    public var technicalIndicators: [String: Double]
    
    public init(date: Date, open: Double, high: Double, low: Double, close: Double, volume: Double, technicalIndicators: [String: Double] = [:]) {
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.technicalIndicators = technicalIndicators
    }
    
    public static func fromCSV(_ csv: String, dateFormat: String = "yyyy-MM-dd") -> [Candlestick] {
        var candlesticks: [Candlestick] = []
        let lines = csv.split(separator: "\n").map { String($0) }
        guard lines.count > 1 else { return [] }
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
            candlesticks.append(Candlestick(date: date, open: open, high: high, low: low, close: close, volume: volume))
        }
        return candlesticks
    }
}
