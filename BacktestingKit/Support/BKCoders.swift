import Foundation

/// Represents `BKCoders` in the BacktestingKit public API.
public enum BKCoders {
    /// Builds a JSON decoder configured for ISO-8601 date decoding.
    public static func iso8601Decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Builds a JSON encoder configured for ISO-8601 date encoding.
    public static func iso8601Encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
