import Foundation

/// Represents `DFSeriesWindow` in the BacktestingKit public API.
public struct DFSeriesWindow<Index, Value> {
    public var indices: [Index]
    public var values: [Value]

    /// Executes `last`.
    public func last() -> Value {
        return values[values.count - 1]
    }

    /// Executes `getIndexLast`.
    public func getIndexLast() -> Index {
        return indices[indices.count - 1]
    }
}

/// Represents `DFSeries` in the BacktestingKit public API.
public struct DFSeries<Index, Value> {
    public var indices: [Index]
    public var values: [Value]

    /// Creates a new instance.
    public init(indices: [Index], values: [Value]) {
        let alignedCount = Swift.min(indices.count, values.count)
        self.indices = Array(indices.prefix(alignedCount))
        self.values = Array(values.prefix(alignedCount))
    }

    /// Creates a new instance.
    public init(pairs: [(Index, Value)]) {
        self.indices = pairs.map { $0.0 }
        self.values = pairs.map { $0.1 }
    }

    /// Executes `count`.
    public func count() -> Int {
        return values.count
    }

    /// Executes `none`.
    public func none() -> Bool {
        return values.isEmpty
    }

    /// Executes `first`.
    public func first() -> Value {
        return values[0]
    }

    /// Executes `last`.
    public func last() -> Value {
        return values[values.count - 1]
    }

    /// Executes `toArray`.
    public func toArray() -> [Value] {
        return values
    }

    /// Executes `toPairs`.
    public func toPairs() -> [(Index, Value)] {
        return Array(Swift.zip(indices, values))
    }

    /// Executes `map`.
    public func map<U>(_ transform: (Value) -> U) -> DFSeries<Index, U> {
        return DFSeries<Index, U>(indices: indices, values: values.map(transform))
    }

    /// Executes `select`.
    public func select<U>(_ transform: (Value) -> U) -> DFSeries<Index, U> {
        return map(transform)
    }

    /// Executes `withIndex`.
    public func withIndex(_ transform: (Value) -> Index) -> DFSeries<Index, Value> {
        let newIndices = values.map(transform)
        return DFSeries<Index, Value>(indices: newIndices, values: values)
    }

    /// Executes `withIndex`.
    public func withIndex(_ newIndex: [Index]) -> DFSeries<Index, Value> {
        return DFSeries<Index, Value>(indices: newIndex, values: values)
    }

    /// Executes `rollingWindow`.
    public func rollingWindow(_ period: Int) -> DFSeries<Index, DFSeriesWindow<Index, Value>> {
        let alignedCount = Swift.min(indices.count, values.count)
        guard period > 0, alignedCount >= period else {
            return DFSeries<Index, DFSeriesWindow<Index, Value>>(indices: [], values: [])
        }
        var outIndices: [Index] = []
        var outValues: [DFSeriesWindow<Index, Value>] = []
        outIndices.reserveCapacity(alignedCount - period + 1)
        outValues.reserveCapacity(alignedCount - period + 1)
        for i in (period - 1)..<alignedCount {
            let windowIndices = Array(indices[(i - period + 1)...i])
            let windowValues = Array(values[(i - period + 1)...i])
            guard let windowIndex = windowIndices.last else { continue }
            outIndices.append(windowIndex)
            outValues.append(DFSeriesWindow(indices: windowIndices, values: windowValues))
        }
        return DFSeries<Index, DFSeriesWindow<Index, Value>>(indices: outIndices, values: outValues)
    }

    /// Executes `zip`.
    public func zip<OtherValue, U>(_ other: DFSeries<Index, OtherValue>, _ zipper: (Value, OtherValue) -> U) -> DFSeries<Index, U> {
        let count = Swift.min(values.count, other.values.count)
        let newIndices = Array(indices.prefix(count))
        let newValues = (0..<count).map { zipper(values[$0], other.values[$0]) }
        return DFSeries<Index, U>(indices: newIndices, values: newValues)
    }

    /// Executes `zipAligned`.
    public func zipAligned<OtherValue, U>(_ other: DFSeries<Index, OtherValue>, _ zipper: (Value, OtherValue) -> U) -> DFSeries<Index, U> where Index: Hashable {
        var otherMap: [Index: OtherValue] = [:]
        for (idx, value) in Swift.zip(other.indices, other.values) {
            otherMap[idx] = value
        }
        var outIndices: [Index] = []
        var outValues: [U] = []
        for (idx, value) in Swift.zip(indices, values) {
            if let otherValue = otherMap[idx] {
                outIndices.append(idx)
                outValues.append(zipper(value, otherValue))
            }
        }
        return DFSeries<Index, U>(indices: outIndices, values: outValues)
    }

    /// Executes `skip`.
    public func skip(_ count: Int) -> DFSeries<Index, Value> {
        if count <= 0 { return self }
        if count >= values.count { return DFSeries(indices: [], values: []) }
        return DFSeries(indices: Array(indices.dropFirst(count)), values: Array(values.dropFirst(count)))
    }

    /// Executes `take`.
    public func take(_ count: Int) -> DFSeries<Index, Value> {
        if count <= 0 { return DFSeries(indices: [], values: []) }
        return DFSeries(indices: Array(indices.prefix(count)), values: Array(values.prefix(count)))
    }

    /// Executes `sortByIndex`.
    public func sortByIndex(ascending: Bool = true) -> DFSeries<Index, Value> where Index: Comparable {
        let pairs = Swift.zip(indices, values).sorted { ascending ? $0.0 < $1.0 : $0.0 > $1.0 }
        return DFSeries(pairs: pairs)
    }

    /// Executes `bake`.
    public func bake() -> DFSeries<Index, Value> {
        return self
    }
}

extension DFSeries where Value == Double {
    /// Executes `average`.
    public func average() -> Double {
        if values.isEmpty { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Executes `variance`.
    public func variance() -> Double {
        if values.isEmpty { return 0 }
        let mean = average()
        let sum = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) }
        return sum / Double(values.count)
    }

    /// Executes `std`.
    public func std() -> Double {
        return sqrt(variance())
    }

    /// Executes `min`.
    public func min() -> Double {
        return values.min() ?? 0
    }

    /// Executes `max`.
    public func max() -> Double {
        return values.max() ?? 0
    }

    /// Executes `amountChange`.
    public func amountChange(_ period: Int) -> DFSeries<Index, Double> {
        let windows = rollingWindow(period)
        let mapped = windows.map { window in
            guard let last = window.values.last, let first = window.values.first else { return 0.0 }
            return last - first
        }
        return DFSeries<Index, Double>(indices: windows.indices, values: mapped.values)
    }

    /// Executes `sma`.
    public func sma(_ period: Int) -> DFSeries<Index, Double> {
        let windows = rollingWindow(period)
        let values = windows.values.map { DFSeries(indices: $0.indices, values: $0.values).average() }
        return DFSeries(indices: windows.indices, values: values)
    }

    /// Executes `ema`.
    public func ema(_ period: Int) -> DFSeries<Index, Double> {
        guard period > 0, values.count >= period else {
            return DFSeries(indices: [], values: [])
        }
        var outIndices: [Index] = []
        var outValues: [Double] = []
        outIndices.reserveCapacity(values.count - period + 1)
        outValues.reserveCapacity(values.count - period + 1)

        let seed = Array(values.prefix(period)).reduce(0, +) / Double(period)
        outIndices.append(indices[period - 1])
        outValues.append(seed)

        if values.count > period {
            let multiplier = 2.0 / Double(period + 1)
            var previous = seed
            for i in period..<values.count {
                let current = (values[i] - previous) * multiplier + previous
                outIndices.append(indices[i])
                outValues.append(current)
                previous = current
            }
        }
        return DFSeries(indices: outIndices, values: outValues)
    }

    /// Executes `rsi`.
    public func rsi(_ period: Int) -> DFSeries<Index, Double> {
        guard period > 0, values.count >= period + 1 else {
            return DFSeries(indices: [], values: [])
        }
        var gains = Array(repeating: 0.0, count: values.count)
        var losses = Array(repeating: 0.0, count: values.count)
        for i in 1..<values.count {
            let delta = values[i] - values[i - 1]
            if delta >= 0 {
                gains[i] = delta
            } else {
                losses[i] = -delta
            }
        }

        var outIndices: [Index] = []
        var outValues: [Double] = []
        outIndices.reserveCapacity(values.count - period)
        outValues.reserveCapacity(values.count - period)

        var averageGain = gains[1...period].reduce(0, +) / Double(period)
        var averageLoss = losses[1...period].reduce(0, +) / Double(period)

        for i in period..<values.count {
            if i > period {
                averageGain = ((averageGain * Double(period - 1)) + gains[i]) / Double(period)
                averageLoss = ((averageLoss * Double(period - 1)) + losses[i]) / Double(period)
            }
            let rsiValue: Double
            if averageLoss < Double.ulpOfOne {
                rsiValue = averageGain < Double.ulpOfOne ? 50.0 : 100.0
            } else {
                let relativeStrength = averageGain / averageLoss
                rsiValue = 100.0 - (100.0 / (1.0 + relativeStrength))
            }
            outIndices.append(indices[i])
            outValues.append(rsiValue)
        }

        return DFSeries(indices: outIndices, values: outValues)
    }

    /// Executes `bollinger`.
    public func bollinger(_ period: Int, _ stdDevMultUpper: Double, _ stdDevMultLower: Double) -> DFDataFrame<Index, DFBollingerRow> {
        let windows = rollingWindow(period)
        var rows: [DFBollingerRow] = []
        for window in windows.values {
            let series = DFSeries(indices: window.indices, values: window.values)
            let avg = series.average()
            let std = series.std()
            let row = DFBollingerRow(
                value: series.last(),
                upper: avg + (std * stdDevMultUpper),
                middle: avg,
                lower: avg - (std * stdDevMultLower),
                stddev: std
            )
            rows.append(row)
        }
        return DFDataFrame(indices: windows.indices, rows: rows)
    }

    /// Executes `macd`.
    public func macd(_ shortPeriod: Int, _ longPeriod: Int, _ signalPeriod: Int) -> DFDataFrame<Index, DFMacdRow> where Index: Hashable {
        let shortEma = ema(shortPeriod)
        let longEma = ema(longPeriod)
        let macd = shortEma.skip(longPeriod - shortPeriod).zip(longEma) { $0 - $1 }
        let signal = macd.ema(signalPeriod)
        let histogram = macd.skip(signalPeriod - 1).zip(signal) { $0 - $1 }

        let merged = DFDataFrame<Index, [String: Double]>.mergeAligned([
            shortEma.inflate { ["shortEMA": $0] },
            longEma.inflate { ["longEMA": $0] },
            macd.inflate { ["macd": $0] },
            signal.inflate { ["signal": $0] },
            histogram.inflate { ["histogram": $0] }
        ])

        return merged.mapRows { dict in
            DFMacdRow(
                shortEMA: dict["shortEMA"] ?? 0,
                longEMA: dict["longEMA"] ?? 0,
                macd: dict["macd"] ?? 0,
                signal: dict["signal"] ?? 0,
                histogram: dict["histogram"] ?? 0
            )
        }
    }
}

/// Represents `DFBollingerRow` in the BacktestingKit public API.
public struct DFBollingerRow {
    public var value: Double
    public var upper: Double
    public var middle: Double
    public var lower: Double
    public var stddev: Double
}

/// Represents `DFMacdRow` in the BacktestingKit public API.
public struct DFMacdRow {
    public var shortEMA: Double
    public var longEMA: Double
    public var macd: Double
    public var signal: Double
    public var histogram: Double
}

/// Represents `DFDataFrame` in the BacktestingKit public API.
public struct DFDataFrame<Index, Row> {
    public var indices: [Index]
    public var rows: [Row]

    /// Creates a new instance.
    public init(indices: [Index], rows: [Row]) {
        let alignedCount = Swift.min(indices.count, rows.count)
        self.indices = Array(indices.prefix(alignedCount))
        self.rows = Array(rows.prefix(alignedCount))
    }

    /// Executes `count`.
    public func count() -> Int {
        return rows.count
    }

    /// Executes `none`.
    public func none() -> Bool {
        return rows.isEmpty
    }

    /// Executes `last`.
    public func last() -> Row {
        return rows[rows.count - 1]
    }

    /// Executes `skip`.
    public func skip(_ count: Int) -> DFDataFrame<Index, Row> {
        if count <= 0 { return self }
        if count >= rows.count { return DFDataFrame(indices: [], rows: []) }
        return DFDataFrame(indices: Array(indices.dropFirst(count)), rows: Array(rows.dropFirst(count)))
    }

    /// Executes `take`.
    public func take(_ count: Int) -> DFDataFrame<Index, Row> {
        if count <= 0 { return DFDataFrame(indices: [], rows: []) }
        return DFDataFrame(indices: Array(indices.prefix(count)), rows: Array(rows.prefix(count)))
    }

    /// Executes `sortByIndex`.
    public func sortByIndex(ascending: Bool = true) -> DFDataFrame<Index, Row> where Index: Comparable {
        let pairs = Swift.zip(indices, rows).sorted { ascending ? $0.0 < $1.0 : $0.0 > $1.0 }
        return DFDataFrame(indices: pairs.map { $0.0 }, rows: pairs.map { $0.1 })
    }

    /// Executes `reindex`.
    public func reindex(_ newIndices: [Index]) -> DFDataFrame<Index, Row?> where Index: Hashable {
        var map: [Index: Row] = [:]
        for (idx, row) in Swift.zip(indices, rows) {
            map[idx] = row
        }
        let newRows = newIndices.map { map[$0] }
        return DFDataFrame<Index, Row?>(indices: newIndices, rows: newRows)
    }

    /// Executes `bake`.
    public func bake() -> DFDataFrame<Index, Row> {
        return self
    }

    /// Executes `deflate`.
    public func deflate<T>(_ selector: (Row) -> T) -> DFSeries<Index, T> {
        return DFSeries(indices: indices, values: rows.map(selector))
    }

    /// Executes `mapRows`.
    public func mapRows<NewRow>(_ transform: (Row) -> NewRow) -> DFDataFrame<Index, NewRow> {
        return DFDataFrame<Index, NewRow>(indices: indices, rows: rows.map(transform))
    }
}

/// Represents `DFIndex` in the BacktestingKit public API.
public struct DFIndex<Value: Comparable & Codable>: Comparable, Codable {
    public var value: Value
    /// Creates a new instance.
    public init(_ value: Value) {
        self.value = value
    }
    public static func < (lhs: DFIndex<Value>, rhs: DFIndex<Value>) -> Bool {
        return lhs.value < rhs.value
    }
}

/// Represents `DFPair` in the BacktestingKit public API.
public struct DFPair<Index, Value> {
    public var index: Index
    public var value: Value
}

/// Represents `DFWhichIndex` in the BacktestingKit public API.
public enum DFWhichIndex: String, Codable {
    case start
    case end
}

extension DFSeries {
    /// Executes `selectPairs`.
    public func selectPairs<U>(_ transform: (Index, Value) -> U) -> DFSeries<Index, U> {
        let newValues = Swift.zip(indices, values).map { transform($0.0, $0.1) }
        return DFSeries<Index, U>(indices: indices, values: newValues)
    }

    /// Executes `filter`.
    public func filter(_ predicate: (Value) -> Bool) -> DFSeries<Index, Value> {
        var outIndices: [Index] = []
        var outValues: [Value] = []
        for (idx, val) in Swift.zip(indices, values) {
            if predicate(val) {
                outIndices.append(idx)
                outValues.append(val)
            }
        }
        return DFSeries(indices: outIndices, values: outValues)
    }

    /// Executes `groupBy`.
    public func groupBy<Key: Hashable>(_ keySelector: (Value) -> Key) -> [Key: DFSeries<Index, Value>] {
        var groups: [Key: [(Index, Value)]] = [:]
        for (idx, val) in Swift.zip(indices, values) {
            let key = keySelector(val)
            groups[key, default: []].append((idx, val))
        }
        return groups.mapValues { DFSeries(pairs: $0) }
    }
}

extension DFDataFrame {
    /// Executes `toPairs`.
    public func toPairs() -> [DFPair<Index, Row>] {
        return Swift.zip(indices, rows).map { DFPair(index: $0.0, value: $0.1) }
    }

    /// Executes `groupBy`.
    public func groupBy<Key: Hashable>(_ keySelector: (Row) -> Key) -> [Key: DFDataFrame<Index, Row>] {
        var groups: [Key: [(Index, Row)]] = [:]
        for (idx, row) in Swift.zip(indices, rows) {
            let key = keySelector(row)
            groups[key, default: []].append((idx, row))
        }
        var result: [Key: DFDataFrame<Index, Row>] = [:]
        for (key, pairs) in groups {
            result[key] = DFDataFrame(indices: pairs.map { $0.0 }, rows: pairs.map { $0.1 })
        }
        return result
    }
}

extension DFDataFrame where Row == [String: Double] {
    public static func merge(_ frames: [DFDataFrame<Index, [String: Double]>]) -> DFDataFrame<Index, [String: Double]> {
        guard let first = frames.first else {
            return DFDataFrame(indices: [], rows: [])
        }
        var mergedRows: [[String: Double]] = Array(repeating: [:], count: first.rows.count)
        mergedRows.indices.forEach { mergedRows[$0].reserveCapacity(8) }
        for frame in frames {
            let count = Swift.min(frame.rows.count, mergedRows.count)
            for i in 0..<count {
                mergedRows[i].merge(frame.rows[i]) { _, new in new }
            }
        }
        return DFDataFrame(indices: first.indices, rows: mergedRows)
    }

    public static func mergeAligned(_ frames: [DFDataFrame<Index, [String: Double]>]) -> DFDataFrame<Index, [String: Double]> where Index: Hashable {
        guard let first = frames.first else {
            return DFDataFrame(indices: [], rows: [])
        }
        var rowMap: [Index: [String: Double]] = [:]
        for frame in frames {
            for (idx, row) in Swift.zip(frame.indices, frame.rows) {
                var merged = rowMap[idx] ?? [:]
                merged.merge(row) { _, new in new }
                rowMap[idx] = merged
            }
        }
        let orderedIndices = first.indices
        let rows = orderedIndices.map { rowMap[$0] ?? [:] }
        return DFDataFrame(indices: orderedIndices, rows: rows)
    }

    /// Executes `column`.
    public func column(_ name: String) -> DFSeries<Index, Double> {
        let values = rows.map { $0[name] ?? 0 }
        return DFSeries(indices: indices, values: values)
    }

    /// Executes `summarize`.
    public func summarize(_ reducers: [String: (DFSeries<Index, Double>) -> Double]) -> [String: Double] {
        var result: [String: Double] = [:]
        for (columnName, reducer) in reducers {
            let series = column(columnName)
            result[columnName] = reducer(series)
        }
        return result
    }

    /// Executes `summarize`.
    public func summarize(_ columns: [String], _ reducer: (DFSeries<Index, Double>) -> Double) -> [String: Double] {
        var result: [String: Double] = [:]
        for columnName in columns {
            result[columnName] = reducer(column(columnName))
        }
        return result
    }
}

extension DFSeries {
    /// Executes `inflate`.
    public func inflate(_ mapper: (Value) -> [String: Double]) -> DFDataFrame<Index, [String: Double]> {
        let rows = values.map(mapper)
        return DFDataFrame(indices: indices, rows: rows)
    }
}

extension DFDataFrame where Row == BKBar {
    /// Executes `withSeries`.
    public func withSeries(_ name: String, _ series: DFSeries<Index, Double>) -> DFDataFrame<Index, BKBar> where Index: Hashable {
        let seriesMap = Dictionary(uniqueKeysWithValues: Swift.zip(series.indices, series.values))
        var newRows = rows
        let alignedCount = Swift.min(indices.count, newRows.count)
        for idx in 0..<alignedCount {
            let rowIndex = indices[idx]
            if let value = seriesMap[rowIndex] {
                var bar = newRows[idx]
                bar.indicators[name] = value
                newRows[idx] = bar
            }
        }
        return DFDataFrame(indices: indices, rows: newRows)
    }

    /// Executes `stochasticK`.
    public func stochasticK(_ period: Int) -> DFSeries<Index, Double> {
        let alignedCount = Swift.min(indices.count, rows.count)
        guard period > 0, alignedCount >= period else {
            return DFSeries(indices: [], values: [])
        }
        var outIndices: [Index] = []
        var outValues: [Double] = []
        for i in (period - 1)..<alignedCount {
            let window = rows[(i - period + 1)...i]
            let low = window.map { $0.low }.min() ?? rows[i].low
            let high = window.map { $0.high }.max() ?? rows[i].high
            let denom = high - low
            let value = denom == 0 ? 0 : (100 * (rows[i].close - low) / denom)
            outIndices.append(indices[i])
            outValues.append(value)
        }
        return DFSeries(indices: outIndices, values: outValues)
    }

    /// Executes `stochasticFast`.
    public func stochasticFast(_ k: Int, _ d: Int) -> DFDataFrame<Index, [String: Double]> where Index: Hashable {
        let fastK = stochasticK(k).bake()
        let fastD = fastK.sma(d)
        return DFDataFrame<Index, [String: Double]>.mergeAligned([
            fastK.inflate { ["percentK": $0] },
            fastD.inflate { ["percentD": $0] }
        ])
    }

    /// Executes `stochasticSlow`.
    public func stochasticSlow(_ k: Int, _ d: Int, _ smooth: Int) -> DFDataFrame<Index, [String: Double]> where Index: Hashable {
        let fastK = stochasticK(k).bake()
        let slowK = fastK.sma(d)
        let slowD = slowK.sma(smooth)
        return DFDataFrame<Index, [String: Double]>.mergeAligned([
            slowK.inflate { ["percentK": $0] },
            slowD.inflate { ["percentD": $0] }
        ])
    }
}

/// Represents `DFDataFrameAny` in the BacktestingKit public API.
public struct DFDataFrameAny {
    public var rows: [[String: Any]]
    /// Creates a new instance.
    public init(rows: [[String: Any]]) {
        self.rows = rows
    }
}

/// Represents `DFJoinType` in the BacktestingKit public API.
public enum DFJoinType: String, Codable {
    case inner
    case left
}

extension DFDataFrame {
    /// Executes `join`.
    public func join<OtherRow, OutputRow>(
        _ other: DFDataFrame<Index, OtherRow>,
        how: DFJoinType = .inner,
        merge: (Row, OtherRow?) -> OutputRow
    ) -> DFDataFrame<Index, OutputRow> where Index: Hashable {
        var otherMap: [Index: OtherRow] = [:]
        for (idx, row) in Swift.zip(other.indices, other.rows) {
            otherMap[idx] = row
        }
        var outIndices: [Index] = []
        var outRows: [OutputRow] = []
        for (idx, row) in Swift.zip(indices, rows) {
            let right = otherMap[idx]
            if how == .inner, case .none = right {
                continue
            }
            outIndices.append(idx)
            outRows.append(merge(row, right))
        }
        return DFDataFrame<Index, OutputRow>(indices: outIndices, rows: outRows)
    }
}

/// Represents `DFPivot` in the BacktestingKit public API.
public struct DFPivot<RowKey: Hashable, ColumnKey: Hashable, Value> {
    public var rows: [RowKey: [ColumnKey: Value]]
    /// Creates a new instance.
    public init(rows: [RowKey: [ColumnKey: Value]]) {
        self.rows = rows
    }
}

extension DFDataFrame {
    /// Executes `pivot`.
    public func pivot<RowKey: Hashable, ColumnKey: Hashable, Value>(
        rowSelector: (Row) -> RowKey,
        columnSelector: (Row) -> ColumnKey,
        valueSelector: (Row) -> Value
    ) -> DFPivot<RowKey, ColumnKey, Value> {
        var result: [RowKey: [ColumnKey: Value]] = [:]
        for row in rows {
            let r = rowSelector(row)
            let c = columnSelector(row)
            let v = valueSelector(row)
            var rowDict = result[r] ?? [:]
            rowDict[c] = v
            result[r] = rowDict
        }
        return DFPivot(rows: result)
    }
}

/// Represents `DFCSV` in the BacktestingKit public API.
public enum DFCSV {
    public static func parse(_ csv: String) -> DFDataFrame<Int, [String: String]> {
        let lines = csv.split(whereSeparator: \.isNewline).map { String($0) }
        guard let header = lines.first else { return DFDataFrame(indices: [], rows: []) }
        let columns = parseCSVLine(header)
        var rows: [[String: String]] = []
        for line in lines.dropFirst() {
            let fields = parseCSVLine(line)
            var row: [String: String] = [:]
            for (idx, col) in columns.enumerated() where idx < fields.count {
                row[col] = fields[idx]
            }
            rows.append(row)
        }
        let indices = Array(0..<rows.count)
        return DFDataFrame(indices: indices, rows: rows)
    }

    public static func parseDoubles(_ csv: String) -> DFDataFrame<Int, [String: Double]> {
        let df = parse(csv)
        let rows = df.rows.map { row in
            var out: [String: Double] = [:]
            for (k, v) in row {
                out[k] = Double(v) ?? 0
            }
            return out
        }
        return DFDataFrame(indices: df.indices, rows: rows)
    }

    public static func toCSV(_ df: DFDataFrame<Int, [String: String]>) -> String {
        guard let first = df.rows.first else { return "" }
        let columns = Array(first.keys)
        var lines: [String] = []
        lines.append(columns.joined(separator: ","))
        for row in df.rows {
            let line = columns.map { escapeCSV(row[$0] ?? "") }.joined(separator: ",")
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }

    public static func toCSV(_ df: DFDataFrame<Int, [String: Double]>) -> String {
        guard let first = df.rows.first else { return "" }
        let columns = Array(first.keys)
        var lines: [String] = []
        lines.append(columns.joined(separator: ","))
        for row in df.rows {
            let line = columns.map { escapeCSV(String(row[$0] ?? 0)) }.joined(separator: ",")
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = line.makeIterator()
        while let ch = iterator.next() {
            if ch == "\"" {
                if inQuotes {
                    if let peek = iterator.next() {
                        if peek == "\"" {
                            current.append("\"")
                        } else if peek == "," {
                            inQuotes = false
                            result.append(current)
                            current = ""
                        } else {
                            inQuotes = false
                            current.append(peek)
                        }
                    } else {
                        inQuotes = false
                    }
                } else {
                    inQuotes = true
                }
            } else if ch == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(ch)
            }
        }
        result.append(current)
        return result.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacing("\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}
