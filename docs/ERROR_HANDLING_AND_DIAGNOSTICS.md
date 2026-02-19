# Error Handling and Diagnostics

This guide maps engine errors to actionable handling patterns.

## Error Categories

## Input/Data Parsing

`BKCSVParsingError`:

- `missingHeader`
- `missingRequiredColumn`
- `invalidDate`
- `invalidISO8601Date(value:line:)`
- `malformedRow(line:)`
- `invalidNumeric(value:line:)`
- `nonChronologicalDate(previous:current:line:)`

Use this category for user-correctable data issues.

## Provider/Network

`AlphaVantageClientError`:

- `invalidTicker`
- `invalidURL`
- `invalidHTTPResponse`
- `badStatusCode`
- `cannotDecodeCSV`
- `throttled`
- `apiError`
- `emptyResponse`

Use retry policy for transient failures and surface vendor errors directly.

## Simulation Input Validation

`BKSimulationDriverError`:

- `emptyInstrumentID`
- `emptyBars`
- `invalidConcurrency`

This category usually indicates request construction issues.

## Batch and Orchestration

`BKEngineFailure` includes:

- `instrumentID`
- `code: BKEngineErrorCode` (`invalidInput`, `network`, `dataParsing`, `datastore`, `simulation`, `unknown`)
- `stage`
- `message`
- `isRetryable`
- `metadata`
- `recoverySuggestion`

Use this for UI-level error cards, grouped retries, and batch summaries.

## Logging Hooks

`BKEngineOneLiner` and `BKQuickDemo` accept a `log` callback.

Recommended pattern:

- include instrument/ticker
- include stage (`fetch`, `parse`, `simulate`, `save`)
- include machine-readable suffixes in metadata keys

## UI Mapping Suggestions

- `dataParsing` -> show line/column issue and import correction help
- `network` -> show retry action
- `datastore` -> show persistence warning and safe retry
- `simulation` -> show rule/config validation message
- `invalidInput` -> show request field validation hints

## Retry Guidance

Retryable candidates:

- network throttling
- temporary datastore unavailability

Non-retryable candidates:

- malformed CSV schema
- non-chronological input
- empty instrument ID

## Diagnostics Checklist

1. Validate CSV order and date format in isolation.
2. Validate provider returns raw CSV and not JSON payload.
3. Run single-instrument detailed simulation before batch.
4. Enable streaming strict parser mode for ingestion debugging.
5. Run parity checks if behavior drift is suspected.
