import Foundation
import BacktestingKit

struct Fixture: Decodable {
    struct OHLCV: Decodable {
        let time: String
        let open: Double
        let high: Double
        let low: Double
        let close: Double
        let volume: Double
    }

    struct V2Rule: Decodable {
        let indicatorOneName: String
        let indicatorOneType: String
        let indicatorOneFigure: [Double]
        let compare: String
        let indicatorTwoName: String
        let indicatorTwoType: String
        let indicatorTwoFigure: [Double]
    }

    struct V2Config: Decodable {
        let policy: String
        let trailingStopLoss: Bool
        let stopLossFigure: Double
        let profitFactor: Double
        let t1: Double
        let t2: Double
    }

    struct V3Rule: Decodable {
        let id: String
        let indicator_one_name: String
        let indicator_one_type: String
        let indicator_one_figure_one: Double
        let indicator_one_figure_two: Double
        let indicator_one_figure_three: Double
        let compare: String
        let indicator_two_name: String
        let indicator_two_type: String
        let indicator_two_figure_one: Double
        let indicator_two_figure_two: Double
        let indicator_two_figure_three: Double
        let rule_type: String
    }

    struct V3Config: Decodable {
        let id: String
        let active: Bool
        let status: String
        let last_status: String
        let policy: String
        let trailing_stop_loss: Bool
        let stop_loss_figure: Double
        let profit_factor: Double
        let t1: Double
        let t2: Double
    }

    struct V2Section: Decodable {
        let config: V2Config
        let entryRules: [V2Rule]
        let exitRules: [V2Rule]
    }

    struct V3Section: Decodable {
        let config: V3Config
        let entryRules: [V3Rule]
        let exitRules: [V3Rule]
    }

    let bars: [OHLCV]
    let v2: V2Section
    let v3: V3Section
}

struct TradeSummary: Codable {
    let entryPrice: Double
    let exitPrice: Double
    let profit: Double
    let holdingPeriod: Double
    let exitReason: String
}

struct AnalysisSummary: Codable {
    let finalCapital: Double
    let profit: Double
    let growth: Double
    let totalTrades: Double
    let maxDrawdown: Double
    let maxDrawdownPct: Double
    let ATMaxDownDraw: Double
    let ATMaxDownDrawPct: Double
}

struct RunSummary: Codable {
    let maxDays: Int
    let seriesCount: Int
    let status: String
    let tradeCount: Int
    let analysis: AnalysisSummary
    let firstTrade: TradeSummary?
    let lastTrade: TradeSummary?
}

struct Output: Codable {
    let v2: RunSummary
    let v3: RunSummary
    let extras: ExtrasSummary
}

struct ExtrasSummary: Codable {
    let equityTail: [Double]
    let drawdownTail: [Double]
}

func decodeModel<T: Decodable>(_ raw: Any) -> T {
    do {
        let data = try JSONSerialization.data(withJSONObject: raw, options: [])
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    } catch {
        fputs("Parity decode failure (\(T.self)): \(error)\n", stderr)
        exit(2)
    }
}

func summarizeAnalysis(_ analysis: ATAnalysis) -> AnalysisSummary {
    AnalysisSummary(
        finalCapital: analysis.finalCapital,
        profit: analysis.profit,
        growth: analysis.growth,
        totalTrades: Double(analysis.totalTrades),
        maxDrawdown: analysis.maxDrawdown,
        maxDrawdownPct: analysis.maxDrawdownPct,
        ATMaxDownDraw: analysis.ATMaxDownDraw,
        ATMaxDownDrawPct: analysis.ATMaxDownDrawPct
    )
}

func summarizeV2Analysis(_ analysis: ATV2.ATAnalysis) -> AnalysisSummary {
    AnalysisSummary(
        finalCapital: analysis.finalCapital,
        profit: analysis.profit,
        growth: analysis.growth,
        totalTrades: analysis.totalTrades,
        maxDrawdown: analysis.maxDrawdown,
        maxDrawdownPct: analysis.maxDrawdownPct,
        ATMaxDownDraw: analysis.ATMaxDownDraw,
        ATMaxDownDrawPct: analysis.ATMaxDownDrawPct
    )
}

func summarizeV2Trade(_ trade: ATV2.ATTrade?) -> TradeSummary? {
    guard let trade else { return nil }
    return TradeSummary(
        entryPrice: trade.entryPrice,
        exitPrice: trade.exitPrice,
        profit: trade.profit,
        holdingPeriod: trade.holdingPeriod,
        exitReason: trade.exitReason
    )
}

func summarizeTrade(_ trade: ATTrade?) -> TradeSummary? {
    guard let trade else { return nil }
    return TradeSummary(
        entryPrice: trade.entryPrice,
        exitPrice: trade.exitPrice,
        profit: trade.profit,
        holdingPeriod: Double(trade.holdingPeriod),
        exitReason: trade.exitReason
    )
}

let fixturePath = "/Users/fung/Programming/backtestingKing-agent/tools/parity/fixture.json"
let fixtureData: Data
do {
    fixtureData = try Data(contentsOf: URL(fileURLWithPath: fixturePath))
} catch {
    fputs("Failed to read parity fixture at \(fixturePath): \(error)\n", stderr)
    exit(2)
}
let fixture: Fixture
do {
    fixture = try JSONDecoder().decode(Fixture.self, from: fixtureData)
} catch {
    fputs("Failed to decode parity fixture: \(error)\n", stderr)
    exit(2)
}

let iso = ISO8601DateFormatter()
let bars = fixture.bars.map { row in
    ATBar(
        time: iso.date(from: row.time) ?? Date(timeIntervalSince1970: 0),
        open: row.open,
        high: row.high,
        low: row.low,
        close: row.close,
        volume: row.volume
    )
}

let rawV2EntryRules: [[String: Any]] = fixture.v2.entryRules.map { rule in
    [
        "indicatorOneName": rule.indicatorOneName,
        "indicatorOneType": rule.indicatorOneType,
        "indicatorOneFigure": rule.indicatorOneFigure.map { Int($0) },
        "compare": rule.compare,
        "indicatorTwoName": rule.indicatorTwoName,
        "indicatorTwoType": rule.indicatorTwoType,
        "indicatorTwoFigure": rule.indicatorTwoFigure.map { Int($0) }
    ]
}
let rawV2ExitRules: [[String: Any]] = fixture.v2.exitRules.map { rule in
    [
        "indicatorOneName": rule.indicatorOneName,
        "indicatorOneType": rule.indicatorOneType,
        "indicatorOneFigure": rule.indicatorOneFigure.map { Int($0) },
        "compare": rule.compare,
        "indicatorTwoName": rule.indicatorTwoName,
        "indicatorTwoType": rule.indicatorTwoType,
        "indicatorTwoFigure": rule.indicatorTwoFigure.map { Int($0) }
    ]
}
let v2EntryRules: [ATV2.SimulationRule] = rawV2EntryRules.map(decodeModel)
let v2ExitRules: [ATV2.SimulationRule] = rawV2ExitRules.map(decodeModel)

let rawV2Config: [String: Any] = [
    "policy": fixture.v2.config.policy,
    "trailingStopLoss": fixture.v2.config.trailingStopLoss,
    "stopLossFigure": fixture.v2.config.stopLossFigure,
    "profitFactor": fixture.v2.config.profitFactor,
    "entryRules": rawV2EntryRules,
    "exitRules": rawV2ExitRules,
    "t1": fixture.v2.config.t1,
    "t2": fixture.v2.config.t2
]
let v2Config: ATV2.SimulationPolicyConfig = decodeModel(rawV2Config)

let (v2Series, v2MaxDays) = v2setTechnicalIndicators(bars, entryRules: v2EntryRules, exitRules: v2ExitRules)
let (v2Output, v2Status) = v2simulateConfig(ticker: "TEST", config: v2Config, entryRules: v2EntryRules, exitRules: v2ExitRules, rawBars: bars)

let rawV3Config: [String: Any] = [
    "id": fixture.v3.config.id,
    "active": fixture.v3.config.active,
    "status": fixture.v3.config.status,
    "last_status": fixture.v3.config.last_status,
    "policy": fixture.v3.config.policy,
    "trailing_stop_loss": fixture.v3.config.trailing_stop_loss,
    "stop_loss_figure": fixture.v3.config.stop_loss_figure,
    "profit_factor": fixture.v3.config.profit_factor,
    "t1": fixture.v3.config.t1,
    "t2": fixture.v3.config.t2,
    "instrument_id": "TEST"
]
let v3Config: ATV3_Config = decodeModel(rawV3Config)

let v3EntryRules: [ATV3_SimulationRule] = fixture.v3.entryRules.map { rule in
    let raw: [String: Any] = [
        "id": rule.id,
        "indicator_one_name": rule.indicator_one_name,
        "indicator_one_type": rule.indicator_one_type,
        "indicator_one_figure_one": rule.indicator_one_figure_one,
        "indicator_one_figure_two": rule.indicator_one_figure_two,
        "indicator_one_figure_three": rule.indicator_one_figure_three,
        "compare": rule.compare,
        "indicator_two_name": rule.indicator_two_name,
        "indicator_two_type": rule.indicator_two_type,
        "indicator_two_figure_one": rule.indicator_two_figure_one,
        "indicator_two_figure_two": rule.indicator_two_figure_two,
        "indicator_two_figure_three": rule.indicator_two_figure_three,
        "rule_type": "entry",
        "instrument_id": "TEST",
        "config_id": fixture.v3.config.id
    ]
    return decodeModel(raw)
}

let v3ExitRules: [ATV3_SimulationRule] = fixture.v3.exitRules.map { rule in
    let raw: [String: Any] = [
        "id": rule.id,
        "indicator_one_name": rule.indicator_one_name,
        "indicator_one_type": rule.indicator_one_type,
        "indicator_one_figure_one": rule.indicator_one_figure_one,
        "indicator_one_figure_two": rule.indicator_one_figure_two,
        "indicator_one_figure_three": rule.indicator_one_figure_three,
        "compare": rule.compare,
        "indicator_two_name": rule.indicator_two_name,
        "indicator_two_type": rule.indicator_two_type,
        "indicator_two_figure_one": rule.indicator_two_figure_one,
        "indicator_two_figure_two": rule.indicator_two_figure_two,
        "indicator_two_figure_three": rule.indicator_two_figure_three,
        "rule_type": "exit",
        "instrument_id": "TEST",
        "config_id": fixture.v3.config.id
    ]
    return decodeModel(raw)
}

let (v3Series, v3MaxDays) = v3setTechnicalIndicators(bars, entryRules: v3EntryRules, exitRules: v3ExitRules)
let (v3Output, v3Status) = v3simulateConfig(ticker: "TEST", config: v3Config, entryRules: v3EntryRules, exitRules: v3ExitRules, rawBars: bars)

let output = Output(
    v2: RunSummary(
        maxDays: v2MaxDays,
        seriesCount: v2Series.count,
        status: v2Status.rawValue,
        tradeCount: v2Output.trades.count,
        analysis: summarizeV2Analysis(v2Output.analysis),
        firstTrade: summarizeV2Trade(v2Output.trades.first),
        lastTrade: summarizeV2Trade(v2Output.trades.last)
    ),
    v3: RunSummary(
        maxDays: v3MaxDays,
        seriesCount: v3Series.count,
        status: v3Status.rawValue,
        tradeCount: v3Output.trades.count,
        analysis: summarizeAnalysis(v3Output.analysis),
        firstTrade: summarizeTrade(v3Output.trades.first),
        lastTrade: summarizeTrade(v3Output.trades.last)
    ),
    extras: {
        let equity = computeEquityCurve(startingCapital: 1_000_000, trades: v3Output.trades)
        let drawdown = computeDrawdown(startingCapital: 1_000_000, trades: v3Output.trades)
        return ExtrasSummary(
            equityTail: Array(equity.suffix(5)),
            drawdownTail: Array(drawdown.suffix(5))
        )
    }()
)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
do {
    let out = try encoder.encode(output)
    print(String(decoding: out, as: UTF8.self))
} catch {
    fputs("Failed to encode parity output: \(error)\n", stderr)
    exit(2)
}
