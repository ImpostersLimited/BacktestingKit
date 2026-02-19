# Data Ingestion and CSV Parsing

## Parsers

- `csvToBars(...)`
- `csvToBarsStreaming(...)`

Both now enforce:

1. **ISO8601 date input** (date-only or ISO datetime forms).
2. **Chronological order** (strictly increasing by date).
3. **Required OHLCV fields**.

## Custom OHLCV Header Mapping

Use `BKCSVColumnMapping` when your input headers differ from defaults.

```swift
let mapping = BKCSVColumnMapping(
    date: "Date",
    open: "Open",
    high: "High",
    low: "Low",
    close: "Close",
    volume: "Volume"
)

let bars = try csvToBars(csv, reverse: false, columnMapping: mapping)
```

## Error Model

CSV parsing reports `BKCSVParsingError` with explicit cases, including:

- `missingHeader`
- `missingRequiredColumn`
- `invalidISO8601Date`
- `malformedRow`
- `invalidNumeric`
- `nonChronologicalDate`

This is designed for UI-friendly error presentation and recovery hints.

## Provider Model (No Hard-Coded Vendor)

Simulation drivers consume `BKRawCsvProvider`. You can inject any market data backend.

Built-ins:

- `BKCustomCsvProvider` for custom async loader closures.
- `BKCachedCsvProvider` for in-memory cache wrapping any provider.
- `AlphaVantageClient` as an optional vendor adapter.

## AlphaVantage (Optional Adapter)

`AlphaVantageClient` supports:

- Retry policy (`AlphaVantageRetryPolicy`)
- Optional request rate limiting (`BKRequestRateLimiter`)
- CSV response retrieval compatible with parser pipeline

## Caching

`BKCachedCsvProvider` wraps any `BKRawCsvProvider` and offers:

- In-memory CSV cache
- Hit/miss metrics (`BKCsvCacheStats`)
- Metrics reporting stream (`BKCacheMetricsReporter`)
