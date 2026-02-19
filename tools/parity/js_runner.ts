import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(scriptDir, "../..");

function resolveJsRoot(): string {
  const envRoot = process.env.JS_ENGINE_ROOT;
  const candidates = [
    envRoot,
    path.resolve(repoRoot, "../js-engine"),
    path.resolve(repoRoot, "../algotrade-js-trial"),
    path.resolve(repoRoot, "js-engine"),
  ].filter((value): value is string => Boolean(value));

  for (const candidate of candidates) {
    const marker = path.resolve(candidate, "algotrade3/models/src/ATTechnicalIndicators.ts");
    if (existsSync(marker)) {
      return candidate;
    }
  }
  throw new Error(
    "JS engine root not found. Set JS_ENGINE_ROOT to a directory containing algotrade3/models."
  );
}

const jsRoot = resolveJsRoot();
const algoRoot = path.resolve(jsRoot, "algotrade3/models");
const fixturePath = path.resolve(scriptDir, "fixture.json");
const fixture = JSON.parse(readFileSync(fixturePath, "utf8"));

function extractExternalImports(source: string): string[] {
  const specs = new Set<string>();
  const fromRegex = /from\s+['"]([^'"]+)['"]/g;
  const sideEffectRegex = /import\s+['"]([^'"]+)['"]/g;
  for (const regex of [fromRegex, sideEffectRegex]) {
    let match: RegExpExecArray | null;
    while ((match = regex.exec(source)) !== null) {
      const spec = match[1];
      if (!spec.startsWith(".") && !spec.startsWith("/")) {
        specs.add(spec);
      }
    }
  }
  return [...specs];
}

async function importExternal(specifier: string): Promise<any> {
  try {
    return await import(specifier);
  } catch {
    const fallback = pathToFileURL(path.resolve(jsRoot, "node_modules", specifier, "build/index.js")).href;
    return await import(fallback);
  }
}

function walkFiles(root: string): string[] {
  const output: string[] = [];
  const stack = [root];
  while (stack.length > 0) {
    const current = stack.pop()!;
    for (const name of readdirSync(current)) {
      const full = path.join(current, name);
      const st = statSync(full);
      if (st.isDirectory()) {
        stack.push(full);
      } else if (st.isFile()) {
        output.push(full);
      }
    }
  }
  return output;
}

function findModuleByExports(root: string, exportsNeeded: string[]): string {
  const files = walkFiles(root).filter((f) => f.endsWith(".ts") || f.endsWith(".js"));
  for (const file of files) {
    const text = readFileSync(file, "utf8");
    const ok = exportsNeeded.every((token) => {
      const direct = new RegExp(`export\\s+(const|function|class)\\s+${token}\\b`).test(text);
      const grouped = new RegExp(`export\\s*\\{[^}]*\\b${token}\\b[^}]*\\}`).test(text);
      return direct || grouped;
    });
    if (ok) return file;
  }
  throw new Error(`Unable to locate module exporting: ${exportsNeeded.join(", ")}`);
}

const indicatorSource = readFileSync(path.resolve(algoRoot, "src/ATTechnicalIndicators.ts"), "utf8");
const externalImports = extractExternalImports(indicatorSource);
const externalModules = await Promise.all(externalImports.map(importExternal));

let DataFrameCtor: any = null;
for (const mod of externalModules) {
  if (typeof mod?.DataFrame === "function") {
    DataFrameCtor = mod.DataFrame;
    break;
  }
  if (typeof mod?.default?.DataFrame === "function") {
    DataFrameCtor = mod.default.DataFrame;
    break;
  }
}
if (!DataFrameCtor) {
  throw new Error("Could not resolve DataFrame constructor from JavaScript runtime dependencies.");
}

const tiModule = await import(pathToFileURL(path.resolve(algoRoot, "src/ATTechnicalIndicators.ts")).href);
const rulesModule = await import(pathToFileURL(path.resolve(algoRoot, "src/ATRuleFunction.ts")).href);
const strategyModule = await import(pathToFileURL(path.resolve(algoRoot, "src/ATStrategy.ts")).href);
const typeModule = await import(pathToFileURL(path.resolve(algoRoot, "src/ATType.ts")).href);

const analysisPath = findModuleByExports(algoRoot, ["analyze", "backtest"]);
const equityPath = findModuleByExports(algoRoot, ["computeEquityCurve"]);
const drawdownPath = findModuleByExports(algoRoot, ["computeDrawdown"]);
const postPath = findModuleByExports(algoRoot, ["postAnalysis", "v3postAnalysis"]);

const analysisModule = await import(pathToFileURL(analysisPath).href);
const equityModule = await import(pathToFileURL(equityPath).href);
const drawdownModule = await import(pathToFileURL(drawdownPath).href);
const postModule = await import(pathToFileURL(postPath).href);

const rows = fixture.bars.map((bar: any) => ({
  time: new Date(bar.time),
  open: bar.open,
  high: bar.high,
  low: bar.low,
  close: bar.close,
  volume: bar.volume,
}));

const frame = new DataFrameCtor(rows);

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
const [v2Series, v2MaxDays] = tiModule.setTechnicalIndicators(frame, fixture.v2.entryRules, fixture.v2.exitRules);
const [v2EntryFn, v2ExitFn] = rulesModule.getCheckingFunction(v2Config);
const v2Strategy = strategyModule.getStrategy(
  v2Config.policy,
  v2Config.stopLossFigure,
  v2EntryFn,
  v2ExitFn,
  v2Config.trailingStopLoss,
  v2Config.profitFactor,
);
const v2Result = analysisModule.backtest(v2Strategy, v2Series, { recordRisk: true, recordStopPrice: true });
const v2Analysis = typeModule.ATAnalysisTypeCheck(postModule.postAnalysis(analysisModule.analyze(1_000_000, v2Result.trades), v2Result.trades, v2Config));
const v2Trades = typeModule.ITradeTypeCheck(v2Result.trades);

const [v3Series, v3MaxDays] = tiModule.v3setTechnicalIndicators(frame, fixture.v3.entryRules, fixture.v3.exitRules);
const [v3EntryFn, v3ExitFn] = rulesModule.v3getCheckingFunction(fixture.v3.entryRules, fixture.v3.exitRules);
const v3Strategy = strategyModule.getStrategy(
  fixture.v3.config.policy,
  fixture.v3.config.stop_loss_figure,
  v3EntryFn,
  v3ExitFn,
  fixture.v3.config.trailing_stop_loss,
  fixture.v3.config.profit_factor,
);
const v3Result = analysisModule.backtest(v3Strategy, v3Series, { recordRisk: true, recordStopPrice: true });
const v3Analysis = typeModule.ATAnalysisTypeCheck(postModule.v3postAnalysis(analysisModule.analyze(1_000_000, v3Result.trades), v3Result.trades, fixture.v3.config));
const v3Trades = typeModule.ITradeTypeCheck(v3Result.trades);

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
    equityTail: equityModule.computeEquityCurve(1_000_000, v3Trades).slice(-5),
    drawdownTail: drawdownModule.computeDrawdown(1_000_000, v3Trades).slice(-5),
  },
};

console.log(JSON.stringify(output, null, 2));
