# BacktestingKit Roadmap

## Kanban

### Backlog
- [ ] Portfolio multi-instrument orchestration API
- [ ] Result export API (JSON/CSV)
- [ ] Structured logging context model
- [ ] Mobile memory budget guardrails
- [ ] Deterministic optimization/Monte Carlo reproducibility

### Ready
- [ ] Property-based tests (parser/date/order invariants)
- [ ] Fuzz tests (CSV malformed rows)
- [ ] Benchmarks (parser modes, large datasets)
- [ ] Deterministic snapshot tests (advanced metrics)
- [ ] Cancellation/timeout coverage (batch simulation)

### In Progress
- [ ] None

### Blocked
- [ ] None

### Done
- [x] Canonical engine entrypoint (`BKEngine`)
- [x] One-liner API (v2/v3)
- [x] Typed `Result` error model (`BKEngineFailure`)
- [x] Result-only execution semantics (no fallback run mode)
- [x] Strict CSV parsing (ISO8601, chronological order, custom OHLCV mapping)
- [x] Optional adjusted-close support
- [x] Provider abstraction (`BKRawCsvProvider`)
- [x] Indicators pack (ATR, ADX, Stochastic, VWAP, OBV, MFI)
- [x] Metrics pack + advanced evaluator
- [x] Execution realism (slippage/commission)
- [x] Position sizing presets (vol-target, fixed-fractional, Kelly-capped)
- [x] Portfolio presets (risk parity, risk-on/risk-off)
- [x] Preset catalog API
- [x] Candle presets: Donchian ATR, Supertrend, Dual EMA+ADX, Bollinger Z, RSI2 MR, VWAP reversion, OBV breakout, MFI trend MR, volatility contraction
- [x] Candle presets: EMA fast/slow ATR, Donchian 20/55 ATR, SMA regime filter, Bollinger band reversion, Z-score 20/60
- [x] Agentic presets: Pulse Dip Rebound, Drift Breather, Volatility Snap, Band VWAP Bridge, Echo Channel Pivot, Ladder Compression Release, RSI Impulse Latch, Dual Anchor Slipstream, ATR Pulse Trail, Slope Switch, Vol Skew Rebound, Median Band Climb, Range Snapback, Momentum Valve
- [x] JS parity tooling (relative-path discovery)
- [x] Demo datasets + quick demo APIs
- [x] DocC + docs set
- [x] SOLID refactor baseline + safety hardening
- [x] POP adoption: unified engine protocol (`BKBacktestingEngine`) + protocol-backed cache metrics abstractions
- [x] Component graph modularization (`BKEngineComponentGraph` + simulation driver factory protocol)
- [x] Simulation driver redundancy reduction (shared result-mapping helpers + task enqueue abstraction)
- [x] UI presentation contracts for payloads/errors (`BKUserPresentablePayload`, `BKUserPresentableError`, `BKResultPresentation`)

### Release
- [ ] API naming audit
- [ ] DocC final pass
- [ ] CI matrix finalization
- [ ] `v0.1.x` release notes
