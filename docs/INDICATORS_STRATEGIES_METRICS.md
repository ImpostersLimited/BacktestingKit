# Indicators, Strategies, and Metrics

This guide summarizes built-in trading analytics in the Swift engine.

## Indicator Families

## Core Indicators

Implemented on `BacktestingKitManager`:

- SMA (`simpleMovingAverage`)
- EMA (`exponentialMovingAverage`)
- RSI (`relativeStrengthIndex`)
- MACD (`macd`)

## Advanced Indicators

Implemented in `BKAdvancedIndicators.swift`:

- ATR (`averageTrueRange`)
- ADX / +DI / -DI (`adx`)
- Stochastic oscillator K/D (`stochasticOscillator`)
- VWAP (`vwap`)
- OBV (`onBalanceVolume`)
- MFI (`moneyFlowIndex`)

Indicator outputs are written into `Candlestick.technicalIndicators` using deterministic keys.

## Strategy APIs

## Core

- SMA crossover backtest via `backtestSMACrossover(...)`
- generic rule-based `backtest(...)` with entry/exit closures

## Advanced

Defined in `BKAdvancedStrategies.swift`:

- EMA crossover (`backtestEMACrossover`)
- RSI mean reversion + trend filter (`backtestRSIMeanReversionWithTrendFilter`)
- Breakout + ATR stop (`backtestBreakoutWithATRStop`)
- Regime switching (`backtestRegimeSwitching`)

Defined in `BKPresetStrategies.swift`:

- Donchian breakout + ATR stop (`backtestDonchianBreakoutWithATRStop`)
- Supertrend (`backtestSupertrend`)
- Dual EMA + ADX filter (`backtestDualEMAWithADXFilter`)
- Bollinger z-score mean reversion (`backtestBollingerZScoreMeanReversion`)
- RSI(2) mean reversion (`backtestRSI2MeanReversion`)
- VWAP reversion (`backtestVWAPReversion`)
- OBV breakout confirmation (`backtestOBVTrendConfirmationBreakout`)
- MFI trend-filtered reversion (`backtestMFITrendFilterReversion`)
- Volatility contraction breakout (`backtestVolatilityContractionBreakout`)
- EMA fast/slow + ATR stop (`backtestEMAFastSlowWithATRStop`)
- Donchian breakout (20/55 style) + ATR stop (`backtestDonchianBreakoutWithATRStop`)
- SMA crossover + ADX regime filter (`backtestSMACrossoverWithRegimeFilter`)
- Bollinger band reversion (`backtestBollingerBandReversion`)
- Z-score reversion (`backtestZScoreReversion`)
- Agentic: Pulse Dip Rebound (`backtestPulseDipRebound`)
- Agentic: Drift Breather (`backtestDriftBreather`)
- Agentic: Volatility Snap (`backtestVolatilitySnap`)
- Agentic: Band VWAP Bridge (`backtestBandVWAPBridge`)
- Agentic: Echo Channel Pivot (`backtestEchoChannelPivot`)
- Agentic: Ladder Compression Release (`backtestLadderCompressionRelease`)
- Agentic: RSI Impulse Latch (`backtestRSIImpulseLatch`)
- Agentic: Dual Anchor Slipstream (`backtestDualAnchorSlipstream`)
- Agentic: ATR Pulse Trail (`backtestAtrPulseTrail`)
- Agentic: Slope Switch (`backtestSlopeSwitch`)
- Agentic: Vol Skew Rebound (`backtestVolSkewRebound`)
- Agentic: Median Band Climb (`backtestMedianBandClimb`)
- Agentic: Range Snapback (`backtestRangeSnapback`)
- Agentic: Momentum Valve (`backtestMomentumValve`)

## Agentic Preset Philosophy

The agentic presets are intentionally **synthetic strategy patterns**, not replicas of common named trading systems.

Design principles used:

- **Composable primitives only**: each preset is built from existing engine primitives (EMA/SMA/ATR/RSI/VWAP/Bollinger + rule closures).
- **Single thesis per preset**: each strategy expresses one dominant behavior (dip rebound, drift continuation, volatility expansion, or anchor reversion).
- **Deterministic and debuggable**: no randomness, no hidden state, and explicit indicator keys so UI/debug tools can inspect decisions.
- **Mobile-safe complexity**: bounded lookbacks and linear-time loops to keep runtime/memory stable on iOS devices.
- **Parity-safe architecture**: presets are additive helpers; they do not alter v2/v3 core model contracts.

Decision-making framework shared by all agentic presets:

1. **Regime gate**: determine whether the market is trend, range, compression, or expansion.
2. **Trigger event**: require a specific local structure change (reclaim, snapback, break, impulse latch).
3. **Persistence filter**: avoid one-bar noise with confirming slope/volatility/flow context.
4. **Exit thesis**: close when the original thesis is fulfilled or invalidated, not only on PnL.

This section explains the **reason**, **philosophy**, and **decision logic** for each preset.

### 1) Pulse Dip Rebound (`backtestPulseDipRebound`)

- **Reason**: many liquid symbols show shallow pullbacks within uptrends; buying controlled weakness can outperform buying breakout highs.
- **Philosophy**: treat dips as temporary inventory imbalance, not trend failure, when higher-timeframe direction remains constructive.
- **Decision model**:
  - Entry: trend-positive state + short-term pullback overshoot.
  - Exit: momentum normalization / mean reclaim / thesis break.
- **Use when**: persistent trend with frequent pullbacks.
- **Avoid when**: persistent downtrend or unstable gap-driven tape.

### 2) Drift Breather (`backtestDriftBreather`)

- **Reason**: trends often alternate between impulse and “breathing” consolidation.
- **Philosophy**: hold the drift phase while structure remains healthy; exit when drift loses coherence.
- **Decision model**:
  - Entry: mild continuation after controlled compression.
  - Exit: slope degradation, expanding chop, or anchor loss.
- **Use when**: smooth directional markets.
- **Avoid when**: violent regime flips or frequent overnight discontinuities.

### 3) Volatility Snap (`backtestVolatilitySnap`)

- **Reason**: volatility expansion can carry directional edge immediately after compression.
- **Philosophy**: trade expansion persistence, not raw volatility itself.
- **Decision model**:
  - Entry: above-baseline expansion aligned with direction.
  - Exit: vol mean-reverts or directional follow-through fails.
- **Use when**: breakouts continue after trigger.
- **Avoid when**: expansion spikes quickly fade.

### 4) Band VWAP Bridge (`backtestBandVWAPBridge`)

- **Reason**: stretched prints below lower bands often reconnect to volume-weighted fair value.
- **Philosophy**: reversion toward anchor is tradable if dislocation is statistical, not structural.
- **Decision model**:
  - Entry: lower-band displacement + anchor deviation.
  - Exit: reconnect to VWAP/centerline or renewed downside acceleration.
- **Use when**: dislocations frequently rebalance intraperiod.
- **Avoid when**: strong trend “walks the band.”

### 5) Echo Channel Pivot (`backtestEchoChannelPivot`)

- **Reason**: channel pullbacks can produce high-quality continuation entries on reclaim.
- **Philosophy**: require evidence of support recovery before committing to trend continuation.
- **Decision model**:
  - Entry: pullback into channel support, then pivot/reclaim confirmation.
  - Exit: channel failure or upside thrust exhaustion.
- **Use when**: orderly channels with repeatable support reactions.
- **Avoid when**: channels break frequently without follow-through.

### 6) Ladder Compression Release (`backtestLadderCompressionRelease`)

- **Reason**: nested compression structures often precede directional release.
- **Philosophy**: volatility energy buildup should be traded at release boundary, not mid-compression.
- **Decision model**:
  - Entry: compression ladder completes + directional break.
  - Exit: failed release or volatility collapse post-break.
- **Use when**: ranges tighten progressively before expansion.
- **Avoid when**: fake-break environments dominate.

### 7) RSI Impulse Latch (`backtestRSIImpulseLatch`)

- **Reason**: fast impulse selloffs frequently produce short-lived reflex rebounds.
- **Philosophy**: “latch” onto impulse extremes with strict normalization exits.
- **Decision model**:
  - Entry: momentum/RSI impulse reaches stretched zone.
  - Exit: RSI normalization, weak rebound structure, or re-acceleration down.
- **Use when**: oversold impulse reversals are common.
- **Avoid when**: persistent trend-down sessions with no reflex.

### 8) Dual Anchor Slipstream (`backtestDualAnchorSlipstream`)

- **Reason**: single-anchor signals are fragile; dual-anchor alignment improves selectivity.
- **Philosophy**: continuation quality increases when both trend and value anchor agree.
- **Decision model**:
  - Entry: price remains in “slipstream” between compatible anchors.
  - Exit: either anchor breaks or spread divergence widens.
- **Use when**: multi-anchor alignment persists.
- **Avoid when**: frequent cross/recross around anchors.

### 9) ATR Pulse Trail (`backtestAtrPulseTrail`)

- **Reason**: fixed exits underperform when volatility regime changes quickly.
- **Philosophy**: trail risk dynamically with ATR so stop distance adapts to market breathing.
- **Decision model**:
  - Entry: directional pulse with acceptable ATR regime.
  - Exit: ATR-informed trailing breach or pulse decay.
- **Use when**: volatility clusters are present.
- **Avoid when**: ultra-low-liquidity bars make ATR noisy.

### 10) Slope Switch (`backtestSlopeSwitch`)

- **Reason**: trend transitions are often visible first in slope alignment shifts.
- **Philosophy**: treat slope agreement/disagreement as an explicit on/off state machine.
- **Decision model**:
  - Entry: fast/slow slope vectors align in same direction.
  - Exit: vector divergence or flattening below threshold.
- **Use when**: directional phases are sustained.
- **Avoid when**: sideway micro-chop flips slope every few bars.

### 11) Vol Skew Rebound (`backtestVolSkewRebound`)

- **Reason**: rebounds are stronger when volatility and money-flow skew confirm asymmetric pressure release.
- **Philosophy**: combine price stretch with flow confirmation to reduce blind mean-reversion.
- **Decision model**:
  - Entry: downside stretch + supportive skew/money-flow.
  - Exit: skew normalization fails or downside pressure reappears.
- **Use when**: skew has predictive value on your instrument universe.
- **Avoid when**: volume/flow proxies are unreliable.

### 12) Median Band Climb (`backtestMedianBandClimb`)

- **Reason**: centerline trends can provide steadier exposure than edge chasing.
- **Philosophy**: prioritize persistence around median structure; exit quickly on centerline failure.
- **Decision model**:
  - Entry: centerline reclaim with supportive drift.
  - Exit: centerline breakdown or failed continuation.
- **Use when**: trend develops around median trajectory.
- **Avoid when**: frequent centerline whipsaws dominate.

### 13) Range Snapback (`backtestRangeSnapback`)

- **Reason**: range extremes often mean-revert when no breakout catalyst exists.
- **Philosophy**: buy/enter only after stretch + initial stabilization signal, not at first touch.
- **Decision model**:
  - Entry: downside range extreme with snapback confirmation.
  - Exit: mid-range/anchor reclaim or renewed breakdown.
- **Use when**: bounded ranges remain intact.
- **Avoid when**: breakout transitions are underway.

### 14) Momentum Valve (`backtestMomentumValve`)

- **Reason**: momentum regimes can decay abruptly; binary “always-on” momentum exposure is fragile.
- **Philosophy**: use a valve model—open exposure when momentum quality is high, close when decay starts.
- **Decision model**:
  - Entry: momentum state crosses quality threshold.
  - Exit: momentum deterioration, histogram/slope decay, or loss of directional confirmation.
- **Use when**: momentum quality persists in runs.
- **Avoid when**: momentum signals oscillate rapidly around neutral.

Practical interpretation:

- These presets are a **catalog of decision archetypes** (continuation, reversion, compression-release, momentum-gated) for testing robustness across regimes.
- They are not intended as “always profitable defaults”; they are intended to help compare behavior under controlled assumptions while keeping engine parity and deterministic behavior.

## Execution Realism

Execution adjustments are available through:

- `BKSlippageModel`
- `BKCommissionModel`
- `executionAdjustedTrades(...)`

Built-in implementations:

- `BKNoSlippageModel`
- `BKFixedBpsSlippageModel`
- `BKNoCommissionModel`
- `BKFixedPlusPercentCommissionModel`

Preset profile:

- `BKExecutionPresetProfile.retailRealistic`

## Position Sizing

Protocol:

- `BKPositionSizingModel`

Built-in:

- `BKVolatilityTargetingSizer`

Preset profile:

- `BKPositionSizingPresetProfile.volatilityTarget15Pct`

Portfolio helper:

- `BKPortfolioPresets.riskParityWeights(...)`

Use this outside parity-critical runs when building portfolio-level simulations.

## Metrics

## Backtest Result Metrics (`BacktestResult`)

- return: `totalReturn`, `annualizedReturn`, `cagr`
- risk: `maxDrawdown`, `volatility`, `ulcerIndex`
- quality: `sharpeRatio`, `sortinoRatio`, `calmarRatio`
- trade distribution: `winRate`, `profitFactor`, `expectancy`, `avgWin`, `avgLoss`
- path details: `avgHoldingPeriod`, streak metrics, `kellyCriterion`

## Report-Level Metrics (`BacktestMetricsReport`)

- compounded vs additive equity curves
- max/average drawdown percent
- downside deviation
- payoff ratio
- recovery factor

## Advanced Performance Metrics (`BKAdvancedPerformanceMetrics`)

- `marRatio`, `omegaRatio`
- `skewness`, `kurtosis`, `tailRatio`
- `var95`, `cvar95`
- `exposurePercent`, `turnoverApprox`
- `averageTradeDurationDays`
- `timeUnderWaterPercent`

Compute via:

- `BacktestingKitManager.advancedPerformanceMetrics(report:candles:minimumAcceptableReturn:)`

## Recommended Usage Pattern

1. Run strategy backtest to get `BacktestResult`.
2. Build `BacktestMetricsReport` for path-dependent metrics.
3. Compute `BKAdvancedPerformanceMetrics` for deeper risk and distribution analysis.
4. Optionally apply execution/commission adjustment and compare gross vs net profiles.
