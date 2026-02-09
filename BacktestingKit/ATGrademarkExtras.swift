import Foundation

public func computeEquityCurve(startingCapital: Double, trades: [ATTrade]) -> [Double] {
    guard startingCapital > 0 else { return [] }
    var equityCurve: [Double] = [startingCapital]
    var workingCapital = startingCapital
    for trade in trades {
        workingCapital *= trade.growth
        equityCurve.append(workingCapital)
    }
    return equityCurve
}

public func computeDrawdown(startingCapital: Double, trades: [ATTrade]) -> [Double] {
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

public typealias ObjectiveFn = (_ trades: [ATTrade]) -> Double

public enum OptimizeSearchDirection: String, Codable {
    case max
    case min
}

public struct ParameterDef: Codable, Equatable {
    public var name: String
    public var startingValue: Double
    public var endingValue: Double
    public var stepSize: Double
}

public enum OptimizationType: String, Codable {
    case grid
    case hillClimb = "hill-climb"
}

public struct OptimizationOptions: Codable, Equatable {
    public var searchDirection: OptimizeSearchDirection?
    public var optimizationType: OptimizationType?
    public var recordAllResults: Bool?
    public var randomSeed: Double?
    public var numStartingPoints: Int?
    public var recordDuration: Bool?

    public init(
        searchDirection: OptimizeSearchDirection? = nil,
        optimizationType: OptimizationType? = nil,
        recordAllResults: Bool? = nil,
        randomSeed: Double? = nil,
        numStartingPoints: Int? = nil,
        recordDuration: Bool? = nil
    ) {
        self.searchDirection = searchDirection
        self.optimizationType = optimizationType
        self.recordAllResults = recordAllResults
        self.randomSeed = randomSeed
        self.numStartingPoints = numStartingPoints
        self.recordDuration = recordDuration
    }
}

public struct OptimizationIterationResult<ParameterT: Codable & Equatable>: Codable, Equatable {
    public var params: ParameterT
    public var result: Double
    public var numTrades: Int
}

public struct OptimizationResult<ParameterT: Codable & Equatable>: Codable, Equatable {
    public var bestResult: Double
    public var bestParameterValues: ParameterT
    public var allResults: [OptimizationIterationResult<ParameterT>]?
    public var durationMS: Double?
}

private struct OptimizationIterationOutput {
    var metric: Double
    var numTrades: Int
}

private func optimizationIteration(
    strategy: ATStrategy,
    parameters: [ParameterDef],
    objectiveFn: ObjectiveFn,
    inputSeries: [ATBar],
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

public func optimize<ParameterT: Codable & Equatable>(
    strategy: ATStrategy,
    parameters: [ParameterDef],
    objectiveFn: ObjectiveFn,
    inputSeries: [ATBar],
    options: OptimizationOptions = OptimizationOptions()
) -> OptimizationResult<ParameterT> {
    var opts = options
    if opts.searchDirection == nil { opts.searchDirection = .max }
    if opts.optimizationType == nil { opts.optimizationType = .grid }

    if opts.optimizationType == .hillClimb {
        return hillClimbOptimization(strategy: strategy, parameters: parameters, objectiveFn: objectiveFn, inputSeries: inputSeries, options: opts)
    }
    return gridSearchOptimization(strategy: strategy, parameters: parameters, objectiveFn: objectiveFn, inputSeries: inputSeries, options: opts)
}

private func hillClimbOptimization<ParameterT: Codable & Equatable>(
    strategy: ATStrategy,
    parameters: [ParameterDef],
    objectiveFn: ObjectiveFn,
    inputSeries: [ATBar],
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
        if visited[key] != nil { continue }

        var workingResult = optimizationIteration(strategy: strategy, parameters: parameters, objectiveFn: objectiveFn, inputSeries: inputSeries, coordinates: workingCoordinates)
        visited[key] = workingResult

        if bestResult == nil || acceptResult(working: bestResult!, next: workingResult.metric, options: options) {
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

                if bestResult == nil || acceptResult(working: bestResult!, next: workingResult.metric, options: options) {
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
    strategy: ATStrategy,
    parameters: [ParameterDef],
    objectiveFn: ObjectiveFn,
    inputSeries: [ATBar],
    options: OptimizationOptions
) -> OptimizationResult<ParameterT> {
    var bestResult: Double?
    var bestCoordinates: [Double] = []
    var results: [OptimizationIterationResult<ParameterT>] = []
    let startTime = Date()

    for coordinates in iterateDimension(workingCoordinates: [], parameterIndex: 0, parameters: parameters) {
        let iteration = optimizationIteration(strategy: strategy, parameters: parameters, objectiveFn: objectiveFn, inputSeries: inputSeries, coordinates: coordinates)
        if bestResult == nil || acceptResult(working: bestResult!, next: iteration.metric, options: options) {
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

public struct WalkForwardOptimizationResult: Codable, Equatable {
    public var trades: [ATTrade]
}

public func walkForwardOptimize(
    strategy: ATStrategy,
    parameters: [ParameterDef],
    objectiveFn: ObjectiveFn,
    inputSeries: [ATBar],
    inSampleSize: Int,
    outSampleSize: Int,
    options: OptimizationOptions = OptimizationOptions()
) -> WalkForwardOptimizationResult {
    guard inSampleSize > 0, outSampleSize > 0 else {
        return WalkForwardOptimizationResult(trades: [])
    }

    var opts = options
    if opts.searchDirection == nil { opts.searchDirection = .max }
    let random = Random(seed: opts.randomSeed ?? 0)

    var workingOffset = 0
    var trades: [ATTrade] = []
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

public struct MonteCarloOptions: Codable, Equatable {
    public var randomSeed: Double?
    public init(randomSeed: Double? = nil) {
        self.randomSeed = randomSeed
    }
}

public func monteCarlo(trades: [ATTrade], numIterations: Int, numSamples: Int, options: MonteCarloOptions = MonteCarloOptions()) -> [[ATTrade]] {
    guard numIterations >= 1, numSamples >= 1 else { return [] }
    if trades.isEmpty { return [] }
    let random = Random(seed: options.randomSeed ?? 0)
    var samples: [[ATTrade]] = []
    for _ in 0..<numIterations {
        var sample: [ATTrade] = []
        for _ in 0..<numSamples {
            let idx = random.getInt(min: 0, max: trades.count - 1)
            sample.append(trades[idx])
        }
        samples.append(sample)
    }
    return samples
}

public final class Random {
    private var state: UInt64

    public init(seed: Double) {
        self.state = UInt64(seed) ^ 0x9E3779B97F4A7C15
        if self.state == 0 { self.state = 0x9E3779B97F4A7C15 }
    }

    public func getReal() -> Double {
        return getReal(min: Double.leastNonzeroMagnitude, max: Double.greatestFiniteMagnitude)
    }

    public func getReal(min: Double, max: Double) -> Double {
        let unit = nextUnit()
        return unit * (max - min) + min
    }

    public func getInt(min: Int, max: Int) -> Int {
        if max <= min { return min }
        let unit = nextUnit()
        return min + Int(floor(unit * Double(max - min + 1)))
    }

    private func nextUnit() -> Double {
        state = 2862933555777941757 &* state &+ 3037000493
        let value = Double(state >> 11) / Double(1 << 53)
        return min(max(value, 0), 1)
    }
}
