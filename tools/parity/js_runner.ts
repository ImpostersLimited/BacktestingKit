import * as df from "/Users/fung/Programming/algotrade-js-trial/node_modules/data-forge/build/index.js";
import "/Users/fung/Programming/algotrade-js-trial/node_modules/data-forge-indicators/build/index.js";
import { readFileSync } from "node:fs";

import { setTechnicalIndicators, v3setTechnicalIndicators } from "/Users/fung/Programming/algotrade-js-trial/algotrade3/models/src/ATTechnicalIndicators.ts";
import { getCheckingFunction, v3getCheckingFunction } from "/Users/fung/Programming/algotrade-js-trial/algotrade3/models/src/ATRuleFunction.ts";
import { getStrategy } from "/Users/fung/Programming/algotrade-js-trial/algotrade3/models/src/ATStrategy.ts";
import { analyze, backtest } from "/Users/fung/Programming/algotrade-js-trial/algotrade3/models/grademark/index.ts";
import { computeEquityCurve } from "/Users/fung/Programming/algotrade-js-trial/algotrade3/models/grademark/lib/compute-equity-curve.ts";
import { computeDrawdown } from "/Users/fung/Programming/algotrade-js-trial/algotrade3/models/grademark/lib/compute-drawdown.ts";
import { postAnalysis, v3postAnalysis } from "/Users/fung/Programming/algotrade-js-trial/algotrade3/models/src/ATPostAnalysis.ts";
import { ATAnalysisTypeCheck, ITradeTypeCheck } from "/Users/fung/Programming/algotrade-js-trial/algotrade3/models/src/ATType.ts";

const fixturePath = "/Users/fung/Programming/backtestingKing-agent/tools/parity/fixture.json";
const fixture = JSON.parse(readFileSync(fixturePath, "utf8"));

const rows = fixture.bars.map((bar: any) => ({
  time: new Date(bar.time),
  open: bar.open,
  high: bar.high,
  low: bar.low,
  close: bar.close,
  volume: bar.volume,
}));

const frame = new df.DataFrame(rows);

function summarizeTrade(trade: any) {
  if (!trade) return null;
  return {
    entryPrice: Number(trade.entryPrice ?? 0),
    exitPrice: Number(trade.exitPrice ?? 0),
    profit: Number(trade.profit ?? 0),
    holdingPeriod: Number(trade.holdingPeriod ?? 0),
    exitReason: String(trade.exitReason ?? ""),
  };
}

function summarizeAnalysis(analysis: any) {
  return {
    finalCapital: Number(analysis.finalCapital ?? 0),
    profit: Number(analysis.profit ?? 0),
    growth: Number(analysis.growth ?? 0),
    totalTrades: Number(analysis.totalTrades ?? 0),
    maxDrawdown: Number(analysis.maxDrawdown ?? 0),
    maxDrawdownPct: Number(analysis.maxDrawdownPct ?? 0),
    ATMaxDownDraw: Number(analysis.ATMaxDownDraw ?? 0),
    ATMaxDownDrawPct: Number(analysis.ATMaxDownDrawPct ?? 0),
  };
}

const v2Config = {
  ...fixture.v2.config,
  entryRules: fixture.v2.entryRules,
  exitRules: fixture.v2.exitRules,
};
const [v2Series, v2MaxDays] = setTechnicalIndicators(frame, fixture.v2.entryRules, fixture.v2.exitRules);
const [v2EntryFn, v2ExitFn] = getCheckingFunction(v2Config);
const v2Strategy = getStrategy(
  v2Config.policy,
  v2Config.stopLossFigure,
  v2EntryFn,
  v2ExitFn,
  v2Config.trailingStopLoss,
  v2Config.profitFactor,
);
const v2Result = backtest(v2Strategy, v2Series, { recordRisk: true, recordStopPrice: true });
const v2Analysis = ATAnalysisTypeCheck(postAnalysis(analyze(1_000_000, v2Result.trades), v2Result.trades, v2Config));
const v2Trades = ITradeTypeCheck(v2Result.trades);

const [v3Series, v3MaxDays] = v3setTechnicalIndicators(frame, fixture.v3.entryRules, fixture.v3.exitRules);
const [v3EntryFn, v3ExitFn] = v3getCheckingFunction(fixture.v3.entryRules, fixture.v3.exitRules);
const v3Strategy = getStrategy(
  fixture.v3.config.policy,
  fixture.v3.config.stop_loss_figure,
  v3EntryFn,
  v3ExitFn,
  fixture.v3.config.trailing_stop_loss,
  fixture.v3.config.profit_factor,
);
const v3Result = backtest(v3Strategy, v3Series, { recordRisk: true, recordStopPrice: true });
const v3Analysis = ATAnalysisTypeCheck(v3postAnalysis(analyze(1_000_000, v3Result.trades), v3Result.trades, fixture.v3.config));
const v3Trades = ITradeTypeCheck(v3Result.trades);

const output = {
  v2: {
    maxDays: v2MaxDays,
    seriesCount: v2Series.count(),
    status: v2Result.lastStatus,
    tradeCount: v2Trades.length,
    analysis: summarizeAnalysis(v2Analysis),
    firstTrade: summarizeTrade(v2Trades[0]),
    lastTrade: summarizeTrade(v2Trades[v2Trades.length - 1]),
  },
  v3: {
    maxDays: v3MaxDays,
    seriesCount: v3Series.count(),
    status: v3Result.lastStatus,
    tradeCount: v3Trades.length,
    analysis: summarizeAnalysis(v3Analysis),
    firstTrade: summarizeTrade(v3Trades[0]),
    lastTrade: summarizeTrade(v3Trades[v3Trades.length - 1]),
  },
  extras: {
    equityTail: computeEquityCurve(1_000_000, v3Trades).slice(-5),
    drawdownTail: computeDrawdown(1_000_000, v3Trades).slice(-5),
  },
};

console.log(JSON.stringify(output, null, 2));
