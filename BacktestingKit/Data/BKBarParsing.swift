import Foundation

/// Defines the `BKBarParsing` contract used by BacktestingKit.
public protocol BKBarParsing {
    func parse(
        csv: String,
        dateFormat: String,
        executionOptions: BKSimulationExecutionOptions
    ) -> Result<[BKBar], BKCSVParsingError>

    func parse(
        csv: String,
        dateFormat: String,
        columnMapping: BKCSVColumnMapping?
    ) -> Result<[BKBar], BKCSVParsingError>
}

/// Represents `BKCSVBarParser` in the BacktestingKit public API.
public struct BKCSVBarParser: BKBarParsing {
    /// Creates a new instance.
    public init() {}

    /// Executes `parse`.
    public func parse(
        csv: String,
        dateFormat: String,
        executionOptions: BKSimulationExecutionOptions
    ) -> Result<[BKBar], BKCSVParsingError> {
        switch executionOptions.parserMode {
        case .legacy:
            return csvToBars(
                csv,
                dateFormat: dateFormat,
                reverse: false,
                columnMapping: executionOptions.csvColumnMapping
            )
        case .streamingLenient:
            return csvToBarsStreaming(
                csv,
                dateFormat: dateFormat,
                reverse: false,
                strict: false,
                maxRows: executionOptions.maxBarsPerInstrument,
                columnMapping: executionOptions.csvColumnMapping
            )
        case .streamingStrict:
            return csvToBarsStreaming(
                csv,
                dateFormat: dateFormat,
                reverse: false,
                strict: true,
                maxRows: executionOptions.maxBarsPerInstrument,
                columnMapping: executionOptions.csvColumnMapping
            )
        }
    }

    /// Executes `parse`.
    public func parse(
        csv: String,
        dateFormat: String,
        columnMapping: BKCSVColumnMapping?
    ) -> Result<[BKBar], BKCSVParsingError> {
        csvToBars(
            csv,
            dateFormat: dateFormat,
            reverse: false,
            columnMapping: columnMapping
        )
    }
}
