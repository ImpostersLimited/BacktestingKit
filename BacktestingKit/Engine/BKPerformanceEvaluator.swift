import Foundation

public extension BacktestingKitManager {
    func advancedPerformanceMetrics(
        report: BacktestMetricsReport,
        candles: [Candlestick],
        minimumAcceptableReturn: Double = 0
    ) -> BKAdvancedPerformanceMetrics {
        let returns = report.tradeReturns
        guard !returns.isEmpty else {
            return BKAdvancedPerformanceMetrics(
                marRatio: 0,
                omegaRatio: 0,
                skewness: 0,
                kurtosis: 0,
                tailRatio: 0,
                var95: 0,
                cvar95: 0,
                exposurePercent: 0,
                turnoverApprox: 0,
                averageTradeDurationDays: 0,
                timeUnderWaterPercent: 0
            )
        }

        let mean = returns.reduce(0, +) / Double(returns.count)
        let centered = returns.map { $0 - mean }
        let m2 = centered.reduce(0) { $0 + ($1 * $1) } / Double(returns.count)
        let sigma = sqrt(max(m2, 0))

        let m3 = centered.reduce(0) { $0 + ($1 * $1 * $1) } / Double(returns.count)
        let m4 = centered.reduce(0) { $0 + ($1 * $1 * $1 * $1) } / Double(returns.count)
        let skew = sigma > 0 ? m3 / pow(sigma, 3) : 0
        let kurt = sigma > 0 ? m4 / pow(sigma, 4) : 0

        let gains = returns.filter { $0 > minimumAcceptableReturn }.map { $0 - minimumAcceptableReturn }
        let losses = returns.filter { $0 < minimumAcceptableReturn }.map { minimumAcceptableReturn - $0 }
        let omega = losses.reduce(0, +) > 0 ? gains.reduce(0, +) / losses.reduce(0, +) : 0

        let sorted = returns.sorted()
        let idx95 = max(0, Int(Double(sorted.count - 1) * 0.05))
        let var95 = sorted[idx95]
        let tail = sorted.prefix(idx95 + 1)
        let cvar95 = tail.isEmpty ? var95 : (tail.reduce(0, +) / Double(tail.count))

        let p95 = sorted[min(sorted.count - 1, Int(Double(sorted.count - 1) * 0.95))]
        let p5 = sorted[idx95]
        let tailRatio = p5 != 0 ? abs(p95 / p5) : 0

        let mar = report.result.maxDrawdown > 0 ? report.result.cagr / report.result.maxDrawdown : 0

        let exposurePercent: Double = {
            guard let first = candles.first?.date, let last = candles.last?.date else { return 0 }
            let totalDays = max(1, Calendar.current.dateComponents([.day], from: first, to: last).day ?? 1)
            let heldDays = report.result.trades.compactMap { $0.bkHoldingPeriodDays() }.reduce(0, +)
            return min(100, (heldDays / Double(totalDays)) * 100)
        }()

        let turnoverApprox = candles.isEmpty ? 0 : Double(report.result.numTrades) / Double(candles.count)
        let averageDuration = report.result.avgHoldingPeriod

        let timeUnderWaterPercent: Double = {
            let curve = report.compoundedEquityCurve
            guard !curve.isEmpty else { return 0 }
            var peak = curve[0]
            var underwater = 0
            for value in curve {
                if value >= peak {
                    peak = value
                } else {
                    underwater += 1
                }
            }
            return (Double(underwater) / Double(curve.count)) * 100
        }()

        return BKAdvancedPerformanceMetrics(
            marRatio: mar,
            omegaRatio: omega,
            skewness: skew,
            kurtosis: kurt,
            tailRatio: tailRatio,
            var95: var95,
            cvar95: cvar95,
            exposurePercent: exposurePercent,
            turnoverApprox: turnoverApprox,
            averageTradeDurationDays: averageDuration,
            timeUnderWaterPercent: timeUnderWaterPercent
        )
    }
}
