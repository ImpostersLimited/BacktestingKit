import Foundation

/// Unified catalog for discoverable simulation-policy presets and candle-based strategy presets.
public enum BKPresetCatalog: String, CaseIterable, Codable, Hashable, Sendable {
    // SimulationPolicy-backed presets
    case sma
    case ema
    case macd
    case stochasticSlow
    case stochasticFast
    case bollinger
    case customStrategy
    case macdSma
    case macdEma
    case smaCrossover
    case emaCrossover
    case smaMeanReversionPolicy
    case emaMeanReversionPolicy

    // Candle-driven strategy presets
    case donchianAtrBreakout
    case supertrend
    case dualEmaAdx
    case bollingerZScoreMeanReversion
    case rsi2MeanReversion
    case vwapReversion
    case obvBreakoutConfirmation
    case mfiTrendReversion
    case volatilityContractionBreakout
    case ema1226AtrStop
    case donchian2055Atr
    case smaRegimeFilter
    case bollingerBandReversion
    case zScoreReversion20
    case zScoreReversion60
    case pulseDipRebound
    case driftBreather
    case volatilitySnap
    case bandVwapBridge
    case echoChannelPivot
    case ladderCompressionRelease
    case rsiImpulseLatch
    case dualAnchorSlipstream
    case atrPulseTrail
    case slopeSwitch
    case volSkewRebound
    case medianBandClimb
    case rangeSnapback
    case momentumValve

    /// Human-readable preset name for UI.
    public var displayName: String {
        switch self {
        case .sma: return "SMA"
        case .ema: return "EMA"
        case .macd: return "MACD"
        case .stochasticSlow: return "Stochastic Slow"
        case .stochasticFast: return "Stochastic Fast"
        case .bollinger: return "Bollinger"
        case .customStrategy: return "Custom Strategy"
        case .macdSma: return "MACD + SMA"
        case .macdEma: return "MACD + EMA"
        case .smaCrossover: return "SMA Crossover"
        case .emaCrossover: return "EMA Crossover"
        case .smaMeanReversionPolicy: return "SMA Mean Reversion"
        case .emaMeanReversionPolicy: return "EMA Mean Reversion"
        case .donchianAtrBreakout: return "Donchian + ATR Breakout"
        case .supertrend: return "Supertrend"
        case .dualEmaAdx: return "Dual EMA + ADX"
        case .bollingerZScoreMeanReversion: return "Bollinger Z-Score MR"
        case .rsi2MeanReversion: return "RSI(2) Mean Reversion"
        case .vwapReversion: return "VWAP Reversion"
        case .obvBreakoutConfirmation: return "OBV Breakout Confirmation"
        case .mfiTrendReversion: return "MFI Trend Reversion"
        case .volatilityContractionBreakout: return "Volatility Contraction Breakout"
        case .ema1226AtrStop: return "EMA(12/26) + ATR Stop"
        case .donchian2055Atr: return "Donchian 20/55 + ATR"
        case .smaRegimeFilter: return "SMA Crossover + Regime Filter"
        case .bollingerBandReversion: return "Bollinger Band Reversion"
        case .zScoreReversion20: return "Z-Score Reversion (20)"
        case .zScoreReversion60: return "Z-Score Reversion (60)"
        case .pulseDipRebound: return "Pulse Dip Rebound"
        case .driftBreather: return "Drift Breather"
        case .volatilitySnap: return "Volatility Snap"
        case .bandVwapBridge: return "Band VWAP Bridge"
        case .echoChannelPivot: return "Echo Channel Pivot"
        case .ladderCompressionRelease: return "Ladder Compression Release"
        case .rsiImpulseLatch: return "RSI Impulse Latch"
        case .dualAnchorSlipstream: return "Dual Anchor Slipstream"
        case .atrPulseTrail: return "ATR Pulse Trail"
        case .slopeSwitch: return "Slope Switch"
        case .volSkewRebound: return "Vol Skew Rebound"
        case .medianBandClimb: return "Median Band Climb"
        case .rangeSnapback: return "Range Snapback"
        case .momentumValve: return "Momentum Valve"
        }
    }

    /// Short preset family label for grouping in UI.
    public var family: String {
        switch self {
        case .sma, .ema, .macd, .stochasticSlow, .stochasticFast, .bollinger, .customStrategy, .macdSma, .macdEma, .smaCrossover, .emaCrossover, .smaMeanReversionPolicy, .emaMeanReversionPolicy:
            return "policy"
        case .donchianAtrBreakout, .supertrend, .dualEmaAdx, .bollingerZScoreMeanReversion, .rsi2MeanReversion, .vwapReversion, .obvBreakoutConfirmation, .mfiTrendReversion, .volatilityContractionBreakout, .ema1226AtrStop, .donchian2055Atr, .smaRegimeFilter, .bollingerBandReversion, .zScoreReversion20, .zScoreReversion60, .pulseDipRebound, .driftBreather, .volatilitySnap, .bandVwapBridge, .echoChannelPivot, .ladderCompressionRelease, .rsiImpulseLatch, .dualAnchorSlipstream, .atrPulseTrail, .slopeSwitch, .volSkewRebound, .medianBandClimb, .rangeSnapback, .momentumValve:
            return "candle"
        }
    }

    /// Backing simulation policy for policy-family presets.
    public var simulationPolicy: SimulationPolicy? {
        switch self {
        case .sma: return .sma
        case .ema: return .ema
        case .macd: return .macd
        case .stochasticSlow: return .stochasticSlow
        case .stochasticFast: return .stochasticFast
        case .bollinger: return .bollinger
        case .customStrategy: return .customStrategy
        case .macdSma: return .macdSma
        case .macdEma: return .macdEma
        case .smaCrossover: return .smaCrossover
        case .emaCrossover: return .emaCrossover
        case .smaMeanReversionPolicy: return .smaMeanReversion
        case .emaMeanReversionPolicy: return .emaMeanReversion
        default: return nil
        }
    }

    /// Builds legacy/policy simulation config when available.
    ///
    /// - Parameters:
    ///   - trailing: Whether trailing stop-loss is enabled.
    ///   - stopLoss: Stop-loss percentage figure.
    /// - Returns: `SimulationPolicyConfig` for policy-family presets, otherwise `nil`.
    public func makeSimulationPolicyConfig(trailing: Bool = true, stopLoss: Double = 15) -> SimulationPolicyConfig? {
        switch self {
        case .sma: return smaPreset(trailing: trailing, stopLoss: stopLoss)
        case .ema: return emaPreset(trailing: trailing, stopLoss: stopLoss)
        case .macd: return macdPreset(trailing: trailing, stopLoss: stopLoss)
        case .stochasticSlow: return stochasticSlowPreset(trailing: trailing, stopLoss: stopLoss)
        case .stochasticFast: return stochasticFastPreset(trailing: trailing, stopLoss: stopLoss)
        case .bollinger: return bollingerPreset(trailing: trailing, stopLoss: stopLoss)
        case .customStrategy: return customPreset(trailing: trailing, stopLoss: stopLoss)
        case .macdSma: return macdSmaPreset(trailing: trailing, stopLoss: stopLoss)
        case .macdEma: return macdEmaPreset(trailing: trailing, stopLoss: stopLoss)
        case .smaCrossover: return smaCrossoverPreset(trailing: trailing, stopLoss: stopLoss)
        case .emaCrossover: return emaCrossoverPreset(trailing: trailing, stopLoss: stopLoss)
        case .smaMeanReversionPolicy: return smaMeanReversion(trailing: trailing, stopLoss: stopLoss)
        case .emaMeanReversionPolicy: return emaMeanReversion(trailing: trailing, stopLoss: stopLoss)
        default: return nil
        }
    }

    /// Executes candle-family presets with default parameters.
    ///
    /// - Parameters:
    ///   - manager: Backtesting manager instance.
    ///   - candles: Input candles in chronological order.
    /// - Returns: Backtest result for candle-family presets, otherwise `nil`.
    public func runCandlePreset(
        with manager: BacktestingKitManager,
        candles: [Candlestick]
    ) -> BacktestResult? {
        switch self {
        case .donchianAtrBreakout:
            return manager.backtestDonchianBreakoutWithATRStop(candles: candles)
        case .supertrend:
            return manager.backtestSupertrend(candles: candles)
        case .dualEmaAdx:
            return manager.backtestDualEMAWithADXFilter(candles: candles)
        case .bollingerZScoreMeanReversion:
            return manager.backtestBollingerZScoreMeanReversion(candles: candles)
        case .rsi2MeanReversion:
            return manager.backtestRSI2MeanReversion(candles: candles)
        case .vwapReversion:
            return manager.backtestVWAPReversion(candles: candles)
        case .obvBreakoutConfirmation:
            return manager.backtestOBVTrendConfirmationBreakout(candles: candles)
        case .mfiTrendReversion:
            return manager.backtestMFITrendFilterReversion(candles: candles)
        case .volatilityContractionBreakout:
            return manager.backtestVolatilityContractionBreakout(candles: candles)
        case .ema1226AtrStop:
            return manager.backtestEMAFastSlowWithATRStop(candles: candles, fastPeriod: 12, slowPeriod: 26)
        case .donchian2055Atr:
            return manager.backtestDonchianBreakoutWithATRStop(candles: candles, entryPeriod: 55, exitPeriod: 20)
        case .smaRegimeFilter:
            return manager.backtestSMACrossoverWithRegimeFilter(candles: candles)
        case .bollingerBandReversion:
            return manager.backtestBollingerBandReversion(candles: candles)
        case .zScoreReversion20:
            return manager.backtestZScoreReversion(candles: candles, lookback: 20)
        case .zScoreReversion60:
            return manager.backtestZScoreReversion(candles: candles, lookback: 60)
        case .pulseDipRebound:
            return manager.backtestPulseDipRebound(candles: candles)
        case .driftBreather:
            return manager.backtestDriftBreather(candles: candles)
        case .volatilitySnap:
            return manager.backtestVolatilitySnap(candles: candles)
        case .bandVwapBridge:
            return manager.backtestBandVWAPBridge(candles: candles)
        case .echoChannelPivot:
            return manager.backtestEchoChannelPivot(candles: candles)
        case .ladderCompressionRelease:
            return manager.backtestLadderCompressionRelease(candles: candles)
        case .rsiImpulseLatch:
            return manager.backtestRSIImpulseLatch(candles: candles)
        case .dualAnchorSlipstream:
            return manager.backtestDualAnchorSlipstream(candles: candles)
        case .atrPulseTrail:
            return manager.backtestAtrPulseTrail(candles: candles)
        case .slopeSwitch:
            return manager.backtestSlopeSwitch(candles: candles)
        case .volSkewRebound:
            return manager.backtestVolSkewRebound(candles: candles)
        case .medianBandClimb:
            return manager.backtestMedianBandClimb(candles: candles)
        case .rangeSnapback:
            return manager.backtestRangeSnapback(candles: candles)
        case .momentumValve:
            return manager.backtestMomentumValve(candles: candles)
        default:
            return nil
        }
    }
}
