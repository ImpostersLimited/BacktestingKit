import Foundation

/// Executes `computeEquityCurve`.
public func computeEquityCurve(startingCapital: Double, trades: [BKTrade]) -> [Double] {
    guard startingCapital > 0 else { return [] }
    var equityCurve: [Double] = [startingCapital]
    var workingCapital = startingCapital
    for trade in trades {
        workingCapital *= trade.growth
        equityCurve.append(workingCapital)
    }
    return equityCurve
}

/// Executes `computeDrawdown`.
public func computeDrawdown(startingCapital: Double, trades: [BKTrade]) -> [Double] {
    guard startingCapital > 0 else { return [] }
    var drawdown: [Double] = [0]
    var workingCapital = startingCapital
    var peakCapital = startingCapital
    var workingDrawdown = 0.0
    for trade in trades {
        workingCapital *= trade.growth
        if workingCapital < peakCapital {
            workingDrawdown = workingCapital - peakCapital
        } else {
            peakCapital = workingCapital
            workingDrawdown = 0
        }
        drawdown.append(workingDrawdown)
    }
    return drawdown
}


private struct OptimizationIterationOutput {
    var metric: Double
    var numTrades: Int
}

private func optimizationIteration(
    strategy: BKStrategy,
    parameters: [ParameterDef],
    objectiveFn: ObjectiveFn,
    inputSeries: [BKBar],
    coordinates: [Double]
) -> OptimizationIterationOutput {
    var overrides: [String: Double] = [:]
    for (idx, param) in parameters.enumerated() where idx < coordinates.count {
        overrides[param.name] = coordinates[idx]
    }
    var strategyClone = strategy
    var merged = strategyClone.parameters
    overrides.forEach { merged[$0.key] = $0.value }
    strategyClone.parameters = merged
    let trades = backtest(strategy: strategyClone, inputSeries: inputSeries).trades
    return OptimizationIterationOutput(metric: objectiveFn(trades), numTrades: trades.count)
}

private func acceptResult(working: Double, next: Double, options: OptimizationOptions) -> Bool {
    if options.searchDirection == .max {
        return next > working
    }
    return next < working
}

private func iterateDimension(
    workingCoordinates: [Double],
    parameterIndex: Int,
    parameters: [ParameterDef]
) -> [[Double]] {
    let parameter = parameters[parameterIndex]
    var results: [[Double]] = []
    var value = parameter.startingValue
    while value <= parameter.endingValue {
        var coords = workingCoordinates
        coords.append(value)
        if parameterIndex < parameters.count - 1 {
            results.append(contentsOf: iterateDimension(workingCoordinates: coords, parameterIndex: parameterIndex + 1, parameters: parameters))
        } else {
            results.append(coords)
        }
        value += parameter.stepSize
    }
    return results
}

private func extractParameterValues<ParameterT: Codable & Equatable>(
    parameters: [ParameterDef],
    coordinates: [Double]
) -> ParameterT {
    var dict: [String: Double] = [:]
    for (idx, param) in parameters.enumerated() where idx < coordinates.count {
        dict[param.name] = coordinates[idx]
    }
    if let casted = dict as? ParameterT {
        return casted
    }
    // Best-effort decode into ParameterT.
    let data = try? JSONSerialization.data(withJSONObject: dict, options: [])
    if let data, let decoded = try? JSONDecoder().decode(ParameterT.self, from: data) {
        return decoded
    }
    let emptyObject = "{}".data(using: .utf8) ?? Data()
    if let decoded = try? JSONDecoder().decode(ParameterT.self, from: emptyObject) {
        return decoded
    }
    preconditionFailure("Unsupported optimization parameter type \(ParameterT.self). Expected a Codable object or [String: Double].")
}

private func packageIterationResult<ParameterT: Codable & Equatable>(
    parameters: [ParameterDef],
    coordinates: [Double],
    result: OptimizationIterationOutput
) -> OptimizationIterationResult<ParameterT> {
    let paramValues: ParameterT = extractParameterValues(parameters: parameters, coordinates: coordinates)
    return OptimizationIterationResult(params: paramValues, result: result.metric, numTrades: result.numTrades)
}

/// Executes `optimize`.
public func optimize<ParameterT: Codable & Equatable>(
    strategy: BKStrategy,
    parameters: [ParameterDef],
    objectiveFn: ObjectiveFn,
    inputSeries: [BKBar],
    options: OptimizationOptions = OptimizationOptions()
) -> OptimizationResult<ParameterT> {
    var opts = options
    opts.searchDirection = opts.searchDirection ?? .max
    opts.optimizationType = opts.optimizationType ?? .grid

    if opts.optimizationType == .hillClimb {
        return hillClimbOptimization(strategy: strategy, parameters: parameters, objectiveFn: objectiveFn, inputSeries: inputSeries, options: opts)
    }
    return gridSearchOptimization(strategy: strategy, parameters: parameters, objectiveFn: objectiveFn, inputSeries: inputSeries, options: opts)
}

private func hillClimbOptimization<ParameterT: Codable & Equatable>(
    strategy: BKStrategy,
    parameters: [ParameterDef],
    objectiveFn: ObjectiveFn,
    inputSeries: [BKBar],
    options: OptimizationOptions
) -> OptimizationResult<ParameterT> {
    var bestResult: Double?
    var bestCoordinates: [Double] = []
    var results: [OptimizationIterationResult<ParameterT>] = []
    let startTime = Date()

    var visited: [String: OptimizationIterationOutput] = [:]
    let random = Random(seed: options.randomSeed ?? 0)
    let numStartingPoints = options.numStartingPoints ?? 4

    for _ in 0..<numStartingPoints {
        var workingCoordinates: [Double] = []
        for parameter in parameters {
            let maxSteps = Int((parameter.endingValue - parameter.startingValue) / parameter.stepSize)
            let randomIncrement = random.getInt(min: 0, max: maxSteps)
            let coordinate = parameter.startingValue + Double(randomIncrement) * parameter.stepSize
            workingCoordinates.append(coordinate)
        }

        let key = workingCoordinates.map { String($0) }.joined(separator: "|")
        if case .some = visited[key] { continue }

        var workingResult = optimizationIteration(strategy: strategy, parameters: parameters, objectiveFn: objectiveFn, inputSeries: inputSeries, coordinates: workingCoordinates)
        visited[key] = workingResult

        if let currentBest = bestResult {
            if acceptResult(working: currentBest, next: workingResult.metric, options: options) {
                bestResult = workingResult.metric
                bestCoordinates = workingCoordinates
            }
        } else {
            bestResult = workingResult.metric
            bestCoordinates = workingCoordinates
        }

        if options.recordAllResults == true {
            results.append(packageIterationResult(parameters: parameters, coordinates: workingCoordinates, result: workingResult))
        }

        while true {
            var gotBetter = false
            for next in getNeighbours(coordinates: workingCoordinates, parameters: parameters) {
                let nextKey = next.map { String($0) }.joined(separator: "|")
                let nextResult = visited[nextKey] ?? optimizationIteration(strategy: strategy, parameters: parameters, objectiveFn: objectiveFn, inputSeries: inputSeries, coordinates: next)
                visited[nextKey] = nextResult

                if options.recordAllResults == true {
                    results.append(packageIterationResult(parameters: parameters, coordinates: workingCoordinates, result: workingResult))
                }

                if let currentBest = bestResult {
                    if acceptResult(working: currentBest, next: workingResult.metric, options: options) {
                        bestResult = workingResult.metric
                        bestCoordinates = workingCoordinates
                    }
                } else {
                    bestResult = workingResult.metric
                    bestCoordinates = workingCoordinates
                }

                if acceptResult(working: workingResult.metric, next: nextResult.metric, options: options) {
                    workingCoordinates = next
                    workingResult = nextResult
                    gotBetter = true
                    break
                }
            }
            if !gotBetter { break }
        }
    }

    let duration = options.recordDuration == true ? Date().timeIntervalSince(startTime) * 1000 : nil
    let bestParams: ParameterT = extractParameterValues(parameters: parameters, coordinates: bestCoordinates)
    return OptimizationResult(
        bestResult: bestResult ?? 0,
        bestParameterValues: bestParams,
        allResults: options.recordAllResults == true ? results : nil,
        durationMS: duration
    )
}

private func gridSearchOptimization<ParameterT: Codable & Equatable>(
    strategy: BKStrategy,
    parameters: [ParameterDef],
    objectiveFn: ObjectiveFn,
    inputSeries: [BKBar],
    options: OptimizationOptions
) -> OptimizationResult<ParameterT> {
    var bestResult: Double?
    var bestCoordinates: [Double] = []
    var results: [OptimizationIterationResult<ParameterT>] = []
    let startTime = Date()

    for coordinates in iterateDimension(workingCoordinates: [], parameterIndex: 0, parameters: parameters) {
        let iteration = optimizationIteration(strategy: strategy, parameters: parameters, objectiveFn: objectiveFn, inputSeries: inputSeries, coordinates: coordinates)
        if let currentBest = bestResult {
            if acceptResult(working: currentBest, next: iteration.metric, options: options) {
                bestResult = iteration.metric
                bestCoordinates = coordinates
            }
        } else {
            bestResult = iteration.metric
            bestCoordinates = coordinates
        }
        if options.recordAllResults == true {
            results.append(packageIterationResult(parameters: parameters, coordinates: coordinates, result: iteration))
        }
    }

    let duration = options.recordDuration == true ? Date().timeIntervalSince(startTime) * 1000 : nil
    let bestParams: ParameterT = extractParameterValues(parameters: parameters, coordinates: bestCoordinates)
    return OptimizationResult(
        bestResult: bestResult ?? 0,
        bestParameterValues: bestParams,
        allResults: options.recordAllResults == true ? results : nil,
        durationMS: duration
    )
}

private func getNeighbours(coordinates: [Double], parameters: [ParameterDef]) -> [[Double]] {
    var results: [[Double]] = []
    for i in 0..<parameters.count {
        var next = coordinates
        next[i] = next[i] + parameters[i].stepSize
        if next[i] <= parameters[i].endingValue {
            results.append(next)
        }
    }
    for i in 0..<parameters.count {
        var next = coordinates
        next[i] = next[i] - parameters[i].stepSize
        if next[i] >= parameters[i].startingValue {
            results.append(next)
        }
    }
    return results
}


/// Executes `walkForwardOptimize`.
public func walkForwardOptimize(
    strategy: BKStrategy,
    parameters: [ParameterDef],
    objectiveFn: ObjectiveFn,
    inputSeries: [BKBar],
    inSampleSize: Int,
    outSampleSize: Int,
    options: OptimizationOptions = OptimizationOptions()
) -> WalkForwardOptimizationResult {
    guard inSampleSize > 0, outSampleSize > 0 else {
        return WalkForwardOptimizationResult(trades: [])
    }

    var opts = options
    opts.searchDirection = opts.searchDirection ?? .max
    let random = Random(seed: opts.randomSeed ?? 0)

    var workingOffset = 0
    var trades: [BKTrade] = []
    while true {
        let inSample = Array(inputSeries.dropFirst(workingOffset).prefix(inSampleSize))
        let outSample = Array(inputSeries.dropFirst(workingOffset + inSampleSize).prefix(outSampleSize))
        if outSample.count < outSampleSize { break }

        opts.randomSeed = random.getReal()
        let optimizeResult: OptimizationResult<[String: Double]> = optimize(
            strategy: strategy,
            parameters: parameters,
            objectiveFn: objectiveFn,
            inputSeries: inSample,
            options: opts
        )

        var strategyClone = strategy
        var merged = strategyClone.parameters
        optimizeResult.bestParameterValues.forEach { merged[$0.key] = $0.value }
        strategyClone.parameters = merged

        let outSampleTrades = backtest(strategy: strategyClone, inputSeries: outSample).trades
        trades.append(contentsOf: outSampleTrades)
        workingOffset += outSampleSize
    }

    return WalkForwardOptimizationResult(trades: trades)
}


/// Executes `monteCarlo`.
public func monteCarlo(trades: [BKTrade], numIterations: Int, numSamples: Int, options: MonteCarloOptions = MonteCarloOptions()) -> [[BKTrade]] {
    guard numIterations >= 1, numSamples >= 1 else { return [] }
    if trades.isEmpty { return [] }
    let random = Random(seed: options.randomSeed ?? 0)
    var samples: [[BKTrade]] = []
    for _ in 0..<numIterations {
        var sample: [BKTrade] = []
        for _ in 0..<numSamples {
            let idx = random.getInt(min: 0, max: trades.count - 1)
            sample.append(trades[idx])
        }
        samples.append(sample)
    }
    return samples
}
