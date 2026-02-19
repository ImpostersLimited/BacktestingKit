import Foundation

public func csvToBars(
    _ csv: String,
    dateFormat: String = "yyyy-MM-dd",
    reverse: Bool = true,
    columnMapping: BKCSVColumnMapping? = nil
) -> Result<[BKBar], BKCSVParsingError> {
    atCSVToBars(
        csv,
        dateFormat: dateFormat,
        reverse: reverse,
        columnMapping: columnMapping
    )
}

private func atCSVToBars(
    _ csv: String,
    dateFormat: String = "yyyy-MM-dd",
    reverse: Bool = true,
    columnMapping: BKCSVColumnMapping? = nil
) -> Result<[BKBar], BKCSVParsingError> {
    _ = dateFormat
    let lines = csv.split(separator: "\n").map { String($0) }
    guard let header = lines.first else {
        return .failure(BKCSVParsingError.missingHeader)
    }
    let columns = header.split(separator: ",").map { atNormalizedColumnKey(String($0)) }
    let indexMap = Dictionary(uniqueKeysWithValues: columns.enumerated().map { ($1, $0) })
    let indices: (
        dateKey: Int,
        openKey: Int,
        highKey: Int,
        lowKey: Int,
        closeKey: Int,
        adjustedCloseKey: Int?,
        volumeKey: Int
    )
    switch atResolveCSVColumnIndices(indexMap: indexMap, columnMapping: columnMapping, strict: false) {
    case .success(let resolvedIndices):
        indices = resolvedIndices
    case .failure(let error):
        return .failure(error)
    }
    let dateKey = indices.dateKey
    let openKey = indices.openKey
    let highKey = indices.highKey
    let lowKey = indices.lowKey
    let closeKey = indices.closeKey
    let adjustedCloseKey = indices.adjustedCloseKey
    let volumeKey = indices.volumeKey

    var bars: [BKBar] = []
    bars.reserveCapacity(max(lines.count - 1, 0))
    var previousDate: Date?
    for (lineIndex, line) in lines.dropFirst().enumerated() {
        let lineNumber = lineIndex + 2
        let fields = line.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        guard fields.count > max(volumeKey, adjustedCloseKey ?? Int.min, closeKey) else {
            return .failure(BKCSVParsingError.malformedRow(line: lineNumber))
        }

        let rawDate = fields[dateKey]
        guard let date = atParseISO8601Date(rawDate) else {
            return .failure(BKCSVParsingError.invalidISO8601Date(value: rawDate, line: lineNumber))
        }
        if let previousDate, date <= previousDate {
            return .failure(BKCSVParsingError.nonChronologicalDate(
                previous: previousDate.ISO8601Format(),
                current: rawDate,
                line: lineNumber
            ))
        }

        guard let open = Double(fields[openKey]) else {
            return .failure(BKCSVParsingError.invalidNumeric(value: fields[openKey], line: lineNumber))
        }
        guard let high = Double(fields[highKey]) else {
            return .failure(BKCSVParsingError.invalidNumeric(value: fields[highKey], line: lineNumber))
        }
        guard let low = Double(fields[lowKey]) else {
            return .failure(BKCSVParsingError.invalidNumeric(value: fields[lowKey], line: lineNumber))
        }
        guard let close = Double(fields[closeKey]) else {
            return .failure(BKCSVParsingError.invalidNumeric(value: fields[closeKey], line: lineNumber))
        }
        let adjustedClose: Double?
        if let adjustedCloseKey {
            guard let parsedAdjustedClose = Double(fields[adjustedCloseKey]) else {
                return .failure(BKCSVParsingError.invalidNumeric(value: fields[adjustedCloseKey], line: lineNumber))
            }
            adjustedClose = parsedAdjustedClose
        } else {
            adjustedClose = nil
        }
        guard let volume = Double(fields[volumeKey]) else {
            return .failure(BKCSVParsingError.invalidNumeric(value: fields[volumeKey], line: lineNumber))
        }

        previousDate = date
        bars.append(
            BKBar(
                time: date,
                open: open,
                high: high,
                low: low,
                close: close,
                adjustedClose: adjustedClose,
                volume: volume
            )
        )
    }

    return .success(reverse ? bars.reversed() : bars)
}

/// Executes `csvToBarsStreaming`.
public func csvToBarsStreaming(
    _ csv: String,
    dateFormat: String = "yyyy-MM-dd",
    reverse: Bool = true,
    strict: Bool = false,
    maxRows: Int? = nil,
    columnMapping: BKCSVColumnMapping? = nil
) -> Result<[BKBar], BKCSVParsingError> {
    atCSVToBarsStreaming(
        csv,
        dateFormat: dateFormat,
        reverse: reverse,
        strict: strict,
        maxRows: maxRows,
        columnMapping: columnMapping
    )
}

private func atCSVToBarsStreaming(
    _ csv: String,
    dateFormat: String = "yyyy-MM-dd",
    reverse: Bool = true,
    strict: Bool = false,
    maxRows: Int? = nil,
    columnMapping: BKCSVColumnMapping? = nil
) -> Result<[BKBar], BKCSVParsingError> {
    _ = dateFormat
    let normalized = csv.replacing("\r\n", with: "\n")
    let allLines = normalized.split(separator: "\n", omittingEmptySubsequences: true)
    guard let headerLine = allLines.first else {
        if strict {
            return .failure(BKCSVParsingError.missingHeader)
        }
        return .success([])
    }

    let headers = headerLine.split(separator: ",").map { atNormalizedColumnKey(String($0)) }
    let indexMap = Dictionary(uniqueKeysWithValues: headers.enumerated().map { ($1, $0) })

    let indices: (
        dateKey: Int,
        openKey: Int,
        highKey: Int,
        lowKey: Int,
        closeKey: Int,
        adjustedCloseKey: Int?,
        volumeKey: Int
    )
    switch atResolveCSVColumnIndices(indexMap: indexMap, columnMapping: columnMapping, strict: strict) {
    case .success(let resolvedIndices):
        indices = resolvedIndices
    case .failure(let error):
        return .failure(error)
    }
    let dateKey = indices.dateKey
    let openKey = indices.openKey
    let highKey = indices.highKey
    let lowKey = indices.lowKey
    let closeKey = indices.closeKey
    let adjustedCloseKey = indices.adjustedCloseKey
    let volumeKey = indices.volumeKey
    let maxRequiredIndex = Swift.max(
        dateKey,
        openKey,
        highKey,
        lowKey,
        closeKey,
        adjustedCloseKey ?? Int.min,
        volumeKey
    )

    var bars: [BKBar] = []
    let boundedCapacity = max(maxRows ?? 0, 0)
    var headIndex = 0
    if boundedCapacity > 0 {
        bars.reserveCapacity(boundedCapacity)
    } else {
        bars.reserveCapacity(Swift.max(allLines.count - 1, 0))
    }

    func appendBounded(_ bar: BKBar) {
        if boundedCapacity == 0 {
            bars.append(bar)
            return
        }
        if bars.count < boundedCapacity {
            bars.append(bar)
            return
        }
        bars[headIndex] = bar
        headIndex = (headIndex + 1) % boundedCapacity
    }
    var previousDate: Date?
    for (lineIndex, rawLine) in allLines.dropFirst().enumerated() {
        let lineNumber = lineIndex + 2
        let fields = rawLine.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        if fields.count <= maxRequiredIndex {
            return .failure(BKCSVParsingError.malformedRow(line: lineNumber))
        }
        let rawDate = fields[dateKey]
        guard let date = atParseISO8601Date(rawDate) else {
            return .failure(BKCSVParsingError.invalidISO8601Date(value: rawDate, line: lineNumber))
        }
        if let previousDate, date <= previousDate {
            return .failure(BKCSVParsingError.nonChronologicalDate(
                previous: previousDate.ISO8601Format(),
                current: rawDate,
                line: lineNumber
            ))
        }
        guard let open = Double(fields[openKey]) else {
            return .failure(BKCSVParsingError.invalidNumeric(value: fields[openKey], line: lineNumber))
        }
        guard let high = Double(fields[highKey]) else {
            return .failure(BKCSVParsingError.invalidNumeric(value: fields[highKey], line: lineNumber))
        }
        guard let low = Double(fields[lowKey]) else {
            return .failure(BKCSVParsingError.invalidNumeric(value: fields[lowKey], line: lineNumber))
        }
        guard let close = Double(fields[closeKey]) else {
            return .failure(BKCSVParsingError.invalidNumeric(value: fields[closeKey], line: lineNumber))
        }
        let adjustedClose: Double?
        if let adjustedCloseKey {
            guard let parsedAdjustedClose = Double(fields[adjustedCloseKey]) else {
                return .failure(BKCSVParsingError.invalidNumeric(value: fields[adjustedCloseKey], line: lineNumber))
            }
            adjustedClose = parsedAdjustedClose
        } else {
            adjustedClose = nil
        }
        guard let volume = Double(fields[volumeKey]) else {
            return .failure(BKCSVParsingError.invalidNumeric(value: fields[volumeKey], line: lineNumber))
        }
        previousDate = date
        appendBounded(
            BKBar(
                time: date,
                open: open,
                high: high,
                low: low,
                close: close,
                adjustedClose: adjustedClose,
                volume: volume
            )
        )
    }

    if boundedCapacity > 0, bars.count == boundedCapacity, headIndex > 0 {
        // Rotate ring-buffered rows back into chronological parse order.
        var rotated: [BKBar] = []
        rotated.reserveCapacity(bars.count)
        rotated.append(contentsOf: bars[headIndex...])
        rotated.append(contentsOf: bars[..<headIndex])
        bars = rotated
    }

    return .success(reverse ? bars.reversed() : bars)
}
