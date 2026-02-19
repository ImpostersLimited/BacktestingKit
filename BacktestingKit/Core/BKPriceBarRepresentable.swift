import Foundation

/// Defines the `BKPriceBarRepresentable` contract used by BacktestingKit.
public protocol BKPriceBarRepresentable {
    var date: Date { get }
    var open: Double { get }
    var high: Double { get }
    var low: Double { get }
    var close: Double { get }
    var adjustedClose: Double? { get }
    var volume: Double { get }
    var technicalIndicators: [String: Double] { get set }

    init(
        date: Date,
        open: Double,
        high: Double,
        low: Double,
        close: Double,
        adjustedClose: Double?,
        volume: Double,
        technicalIndicators: [String: Double]
    )
}

public extension BKPriceBarRepresentable {
    func replacingTechnicalIndicators(_ technicalIndicators: [String: Double]) -> Self {
        Self(
            date: date,
            open: open,
            high: high,
            low: low,
            close: close,
            adjustedClose: adjustedClose,
            volume: volume,
            technicalIndicators: technicalIndicators
        )
    }
}
