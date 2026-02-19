import Foundation

public final class Random {
    private var state: UInt64

    /// Creates a new instance.
    public init(seed: Double) {
        self.state = UInt64(seed) ^ 0x9E3779B97F4A7C15
        if self.state == 0 { self.state = 0x9E3779B97F4A7C15 }
    }

    /// Executes `getReal`.
    public func getReal() -> Double {
        return getReal(min: Double.leastNonzeroMagnitude, max: Double.greatestFiniteMagnitude)
    }

    /// Executes `getReal`.
    public func getReal(min: Double, max: Double) -> Double {
        let unit = nextUnit()
        return unit * (max - min) + min
    }

    /// Executes `getInt`.
    public func getInt(min: Int, max: Int) -> Int {
        if max <= min { return min }
        let unit = nextUnit()
        return min + Int(floor(unit * Double(max - min + 1)))
    }

    private func nextUnit() -> Double {
        state = 2862933555777941757 &* state &+ 3037000493
        let value = Double(state >> 11) / Double(1 << 53)
        return min(max(value, 0), 1)
    }
}
