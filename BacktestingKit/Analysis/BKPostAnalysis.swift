import Foundation

/// Executes `v3postAnalysis`.
public func v3postAnalysis(analysis: BKAnalysis, trades: [BKTrade], config: BKV3_Config) -> BKAnalysis {
    var globalDrawdownPct = 0.0
    var globalDrawdown = 0.0

    if config.trailingStopLoss ?? false {
        for trade in trades {
            var localMax = -Double.infinity
            var localMin = Double.infinity
            var previousEdit: BKMinMax?
            var drawdownPct = 0.0
            var drawdown = 0.0
            for i in 0..<trade.stopPriceSeries.count {
                let curStopLoss = trade.stopPriceSeries[i].value
                let riskPct = trade.riskSeries.indices.contains(i) ? trade.riskSeries[i].value : 0
                let factor = 1 - (riskPct / 100)
                let close = factor == 0 ? curStopLoss : curStopLoss / factor
                if let _ = previousEdit {
                    if close > localMax {
                        localMax = close
                        localMin = close
                        previousEdit = .max
                    } else if close < localMin {
                        localMin = close
                        previousEdit = .min
                        let tempPct = (localMax - localMin) / localMax * 100
                        if tempPct > drawdownPct {
                            drawdownPct = tempPct
                            drawdown = localMax - localMin
                        }
                    }
                } else {
                    localMax = close
                    localMin = close
                    drawdownPct = 0
                    drawdown = 0
                    previousEdit = .max
                }
            }
            if drawdownPct > globalDrawdownPct {
                globalDrawdownPct = drawdownPct
                globalDrawdown = drawdown
            }
        }
    } else {
        for trade in trades {
            var localMax = -Double.infinity
            var localMin = Double.infinity
            var previousEdit: BKMinMax?
            var drawdownPct = 0.0
            var drawdown = 0.0
            for i in 0..<trade.riskSeries.count {
                let curStopLoss = trade.stopPrice
                let riskPct = trade.riskSeries[i].value
                let factor = 1 - (riskPct / 100)
                let close = factor == 0 ? curStopLoss : curStopLoss / factor
                if let _ = previousEdit {
                    if close > localMax {
                        localMax = close
                        localMin = close
                        previousEdit = .max
                    } else if close < localMin {
                        localMin = close
                        previousEdit = .min
                        let tempPct = (localMax - localMin) / localMax * 100
                        if tempPct > drawdownPct {
                            drawdownPct = tempPct
                            drawdown = localMax - localMin
                        }
                    }
                } else {
                    localMax = close
                    localMin = close
                    drawdownPct = 0
                    drawdown = 0
                    previousEdit = .max
                }
            }
            if drawdownPct > globalDrawdownPct {
                globalDrawdownPct = drawdownPct
                globalDrawdown = drawdown
            }
        }
    }

    var result = analysis
    result.BKMaxDownDraw = globalDrawdown
    result.BKMaxDownDrawPct = globalDrawdownPct
    return result
}

/// Executes `postAnalysis`.
public func postAnalysis(analysis: BKAnalysis, trades: [BKTrade], config: BKV2.SimulationPolicyConfig) -> BKAnalysis {
    var globalDrawdownPct = 0.0
    var globalDrawdown = 0.0

    if config.trailingStopLoss {
        for trade in trades {
            var localMax = -Double.infinity
            var localMin = Double.infinity
            var previousEdit: BKMinMax?
            var drawdownPct = 0.0
            var drawdown = 0.0
            for i in 0..<trade.stopPriceSeries.count {
                let curStopLoss = trade.stopPriceSeries[i].value
                let riskPct = trade.riskSeries.indices.contains(i) ? trade.riskSeries[i].value : 0
                let factor = 1 - (riskPct / 100)
                let close = factor == 0 ? curStopLoss : curStopLoss / factor
                if let _ = previousEdit {
                    if close > localMax {
                        localMax = close
                        localMin = close
                        previousEdit = .max
                    } else if close < localMin {
                        localMin = close
                        previousEdit = .min
                        let tempPct = (localMax - localMin) / localMax * 100
                        if tempPct > drawdownPct {
                            drawdownPct = tempPct
                            drawdown = localMax - localMin
                        }
                    }
                } else {
                    localMax = close
                    localMin = close
                    drawdownPct = 0
                    drawdown = 0
                    previousEdit = .max
                }
            }
            if drawdownPct > globalDrawdownPct {
                globalDrawdownPct = drawdownPct
                globalDrawdown = drawdown
            }
        }
    } else {
        for trade in trades {
            var localMax = -Double.infinity
            var localMin = Double.infinity
            var previousEdit: BKMinMax?
            var drawdownPct = 0.0
            var drawdown = 0.0
            for i in 0..<trade.riskSeries.count {
                let curStopLoss = trade.stopPrice
                let riskPct = trade.riskSeries[i].value
                let factor = 1 - (riskPct / 100)
                let close = factor == 0 ? curStopLoss : curStopLoss / factor
                if let _ = previousEdit {
                    if close > localMax {
                        localMax = close
                        localMin = close
                        previousEdit = .max
                    } else if close < localMin {
                        localMin = close
                        previousEdit = .min
                        let tempPct = (localMax - localMin) / localMax * 100
                        if tempPct > drawdownPct {
                            drawdownPct = tempPct
                            drawdown = localMax - localMin
                        }
                    }
                } else {
                    localMax = close
                    localMin = close
                    drawdownPct = 0
                    drawdown = 0
                    previousEdit = .max
                }
            }
            if drawdownPct > globalDrawdownPct {
                globalDrawdownPct = drawdownPct
                globalDrawdown = drawdown
            }
        }
    }

    var result = analysis
    result.BKMaxDownDraw = globalDrawdown
    result.BKMaxDownDrawPct = globalDrawdownPct
    return result
}
