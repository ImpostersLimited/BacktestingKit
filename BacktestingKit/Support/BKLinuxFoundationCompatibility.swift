#if os(Linux)
import Foundation

extension Date {
    func ISO8601Format() -> String {
        BKLinuxISO8601.formatter.string(from: self)
    }
}

private enum BKLinuxISO8601 {
    static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

// ponytail: Linux Swift 5.9 lacks the Foundation formatting APIs used by this package; remove when the minimum Linux toolchain supplies them.
struct FloatingPointFormatStyle<Value: BinaryFloatingPoint> {
    var fractionLength: Int?

    static var number: Self {
        Self()
    }

    func precision(_ precision: FloatingPointFormatPrecision) -> Self {
        var copy = self
        copy.fractionLength = precision.fractionLength
        return copy
    }
}

struct FloatingPointFormatPrecision {
    var fractionLength: Int

    static func fractionLength(_ value: Int) -> Self {
        Self(fractionLength: value)
    }
}

extension BinaryFloatingPoint {
    func formatted(_ style: FloatingPointFormatStyle<Self>) -> String {
        let length = max(0, style.fractionLength ?? 6)
        return String(format: "%.\(length)f", Double(self))
    }
}
#endif
