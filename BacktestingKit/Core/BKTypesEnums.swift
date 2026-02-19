import Foundation

/// Represents `BKEntitlement` in the BacktestingKit public API.
public enum BKEntitlement: String, Codable {
    case pro
    case standard
}

/// Represents `TierSet` in the BacktestingKit public API.
public enum TierSet: String, Codable {
    case pro
    case standard
}

/// Represents `BKMinMax` in the BacktestingKit public API.
public enum BKMinMax: String, Codable {
    case min
    case max
}

/// Represents `CompareOption` in the BacktestingKit public API.
public enum CompareOption: String, Codable {
    case largerOrEqualTo
    case largerThan
    case equalTo
    case smallThan
    case smallerOrEqualTo
}

/// Represents `SimulationPolicy` in the BacktestingKit public API.
public enum SimulationPolicy: String, Codable {
    case sma
    case ema
    case macd
    case stochasticSlow
    case stochasticFast
    case bollinger
    case macdSma
    case macdEma
    case smaCrossover
    case emaCrossover
    case smaMeanReversion
    case emaMeanReversion
    case customStrategy = "CUSTOM_STRATEGY"
}

/// Represents `TechnicalIndicators` in the BacktestingKit public API.
public enum TechnicalIndicators: String, Codable {
    case sma
    case macd
    case ema
    case bollingerUpper
    case bollingerLower
    case bollingerMiddle
    case rsi
    case stochasticSlowPercentD
    case stochasticSlowPercentK
    case stochasticFastPercentD
    case stochasticFastPercentK
    case close
    case constant
}

/// Represents `SimulationStatus` in the BacktestingKit public API.
public enum SimulationStatus: String, Codable {
    case pending
    case simulating
    case finished
    case failed
}

/// Represents `BKAnalysis` in the BacktestingKit public API.
