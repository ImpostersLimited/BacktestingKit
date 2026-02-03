import Foundation

public func v3postAnalysis(analysis: ATAnalysis, trades: [ATTrade], config: ATV3_Config) -> ATAnalysis {
    var globalDrawdownPct = 0.0
    var globalDrawdown = 0.0

    if config.trailingStopLoss ?? false {
        for trade in trades {
            var localMax = -Double.infinity
            var localMin = Double.infinity
            var previousEdit: ATMinMax?
            var drawdownPct = 0.0
            var drawdown = 0.0
            for i in 0..<trade.stopPriceSeries.count {
                let curStopLoss = trade.stopPriceSeries[i].value
                let riskPct = trade.riskSeries.indices.contains(i) ? trade.riskSeries[i].value : 0
                let factor = 1 - (riskPct / 100)
                let close = factor == 0 ? curStopLoss : curStopLoss / factor
                if previousEdit == nil {
                    localMax = close
                    localMin = close
                    drawdownPct = 0
                    drawdown = 0
                    previousEdit = .max
                } else {
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
            var previousEdit: ATMinMax?
            var drawdownPct = 0.0
            var drawdown = 0.0
            for i in 0..<trade.riskSeries.count {
                let curStopLoss = trade.stopPrice
                let riskPct = trade.riskSeries[i].value
                let factor = 1 - (riskPct / 100)
                let close = factor == 0 ? curStopLoss : curStopLoss / factor
                if previousEdit == nil {
                    localMax = close
                    localMin = close
                    drawdownPct = 0
                    drawdown = 0
                    previousEdit = .max
                } else {
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
                }
            }
            if drawdownPct > globalDrawdownPct {
                globalDrawdownPct = drawdownPct
                globalDrawdown = drawdown
            }
        }
    }

    var result = analysis
    result.ATMaxDownDraw = globalDrawdown
    result.ATMaxDownDrawPct = globalDrawdownPct
    return result
}

public func postAnalysis(analysis: ATAnalysis, trades: [ATTrade], config: ATV2.SimulationPolicyConfig) -> ATAnalysis {
    var globalDrawdownPct = 0.0
    var globalDrawdown = 0.0

    if config.trailingStopLoss {
        for trade in trades {
            var localMax = -Double.infinity
            var localMin = Double.infinity
            var previousEdit: ATMinMax?
            var drawdownPct = 0.0
            var drawdown = 0.0
            for i in 0..<trade.stopPriceSeries.count {
                let curStopLoss = trade.stopPriceSeries[i].value
                let riskPct = trade.riskSeries.indices.contains(i) ? trade.riskSeries[i].value : 0
                let factor = 1 - (riskPct / 100)
                let close = factor == 0 ? curStopLoss : curStopLoss / factor
                if previousEdit == nil {
                    localMax = close
                    localMin = close
                    drawdownPct = 0
                    drawdown = 0
                    previousEdit = .max
                } else {
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
            var previousEdit: ATMinMax?
            var drawdownPct = 0.0
            var drawdown = 0.0
            for i in 0..<trade.riskSeries.count {
                let curStopLoss = trade.stopPrice
                let riskPct = trade.riskSeries[i].value
                let factor = 1 - (riskPct / 100)
                let close = factor == 0 ? curStopLoss : curStopLoss / factor
                if previousEdit == nil {
                    localMax = close
                    localMin = close
                    drawdownPct = 0
                    drawdown = 0
                    previousEdit = .max
                } else {
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
                }
            }
            if drawdownPct > globalDrawdownPct {
                globalDrawdownPct = drawdownPct
                globalDrawdown = drawdown
            }
        }
    }

    var result = analysis
    result.ATMaxDownDraw = globalDrawdown
    result.ATMaxDownDrawPct = globalDrawdownPct
    return result
}
