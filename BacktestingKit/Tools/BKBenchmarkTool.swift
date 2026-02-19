import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// A single benchmark sample.
public struct BKBenchmarkSample: Codable, Equatable {
    /// Zero-based measured iteration index.
    public var iteration: Int
    /// Sample duration in milliseconds.
    public var durationMS: Double
    /// Optional resident-memory delta for the sample.
    public var memoryDeltaBytes: UInt64?

    /// Creates a new benchmark sample.
    public init(iteration: Int, durationMS: Double, memoryDeltaBytes: UInt64?) {
        self.iteration = iteration
        self.durationMS = durationMS
        self.memoryDeltaBytes = memoryDeltaBytes
    }
}

/// Aggregated statistics from a benchmark run.
public struct BKBenchmarkResult: Codable, Equatable {
    /// Logical benchmark identifier.
    public var name: String
    /// Number of measured iterations.
    public var iterations: Int
    /// Mean duration across samples.
    public var meanMS: Double
    /// 50th percentile duration.
    public var p50MS: Double
    /// 95th percentile duration.
    public var p95MS: Double
    /// Minimum sampled duration.
    public var minMS: Double
    /// Maximum sampled duration.
    public var maxMS: Double
    /// Raw sample data.
    public var samples: [BKBenchmarkSample]

    /// Creates a new benchmark result.
    public init(
        name: String,
        iterations: Int,
        meanMS: Double,
        p50MS: Double,
        p95MS: Double,
        minMS: Double,
        maxMS: Double,
        samples: [BKBenchmarkSample]
    ) {
        self.name = name
        self.iterations = iterations
        self.meanMS = meanMS
        self.p50MS = p50MS
        self.p95MS = p95MS
        self.minMS = minMS
        self.maxMS = maxMS
        self.samples = samples
    }
}

/// Benchmark helpers for repeatable micro-performance measurement.
public enum BKBenchmarkTool {
    /// Runs a synchronous benchmark block.
    ///
    /// - Parameters:
    ///   - name: Logical benchmark name.
    ///   - iterations: Number of measured iterations.
    ///   - warmup: Number of warm-up iterations excluded from result samples.
    ///   - measureMemory: Whether to include per-sample resident memory deltas.
    ///   - block: Code block to benchmark.
    /// - Returns: Aggregated benchmark result.
    public static func run(
        name: String,
        iterations: Int = 20,
        warmup: Int = 3,
        measureMemory: Bool = true,
        block: () -> Void
    ) -> BKBenchmarkResult {
        runInternal(
            name: name,
            iterations: iterations,
            warmup: warmup,
            measureMemory: measureMemory
        ) {
            block()
        }
    }

    /// Runs an asynchronous benchmark block.
    ///
    /// - Parameters:
    ///   - name: Logical benchmark name.
    ///   - iterations: Number of measured iterations.
    ///   - warmup: Number of warm-up iterations excluded from result samples.
    ///   - measureMemory: Whether to include per-sample resident memory deltas.
    ///   - block: Async code block to benchmark.
    /// - Returns: Aggregated benchmark result.
    public static func runAsync(
        name: String,
        iterations: Int = 20,
        warmup: Int = 3,
        measureMemory: Bool = true,
        block: () async -> Void
    ) async -> BKBenchmarkResult {
        await runInternalAsync(
            name: name,
            iterations: iterations,
            warmup: warmup,
            measureMemory: measureMemory
        ) {
            await block()
        }
    }

    private static func runInternal(
        name: String,
        iterations: Int,
        warmup: Int,
        measureMemory: Bool,
        block: () -> Void
    ) -> BKBenchmarkResult {
        let effectiveIterations = max(1, iterations)
        let effectiveWarmup = max(0, warmup)
        for _ in 0..<effectiveWarmup {
            block()
        }

        var samples: [BKBenchmarkSample] = []
        samples.reserveCapacity(effectiveIterations)
        for iteration in 0..<effectiveIterations {
            let memoryBefore = measureMemory ? bkCurrentResidentMemory() : nil
            let startedAt = DispatchTime.now().uptimeNanoseconds
            block()
            let endedAt = DispatchTime.now().uptimeNanoseconds
            let durationMS = Double(endedAt - startedAt) / 1_000_000.0
            let memoryAfter = measureMemory ? bkCurrentResidentMemory() : nil
            let memoryDelta = bkMemoryDeltaBytes(before: memoryBefore, after: memoryAfter)
            samples.append(BKBenchmarkSample(iteration: iteration, durationMS: durationMS, memoryDeltaBytes: memoryDelta))
        }
        return bkBuildBenchmarkResult(name: name, samples: samples)
    }

    private static func runInternalAsync(
        name: String,
        iterations: Int,
        warmup: Int,
        measureMemory: Bool,
        block: () async -> Void
    ) async -> BKBenchmarkResult {
        let effectiveIterations = max(1, iterations)
        let effectiveWarmup = max(0, warmup)
        for _ in 0..<effectiveWarmup {
            await block()
        }

        var samples: [BKBenchmarkSample] = []
        samples.reserveCapacity(effectiveIterations)
        for iteration in 0..<effectiveIterations {
            let memoryBefore = measureMemory ? bkCurrentResidentMemory() : nil
            let startedAt = DispatchTime.now().uptimeNanoseconds
            await block()
            let endedAt = DispatchTime.now().uptimeNanoseconds
            let durationMS = Double(endedAt - startedAt) / 1_000_000.0
            let memoryAfter = measureMemory ? bkCurrentResidentMemory() : nil
            let memoryDelta = bkMemoryDeltaBytes(before: memoryBefore, after: memoryAfter)
            samples.append(BKBenchmarkSample(iteration: iteration, durationMS: durationMS, memoryDeltaBytes: memoryDelta))
        }
        return bkBuildBenchmarkResult(name: name, samples: samples)
    }
}

private func bkBuildBenchmarkResult(name: String, samples: [BKBenchmarkSample]) -> BKBenchmarkResult {
    let durations = samples.map(\.durationMS).sorted()
    let count = max(durations.count, 1)
    let sum = durations.reduce(0, +)
    let mean = durations.isEmpty ? 0 : sum / Double(durations.count)
    let p50 = durations.isEmpty ? 0 : durations[min(durations.count - 1, Int(Double(durations.count - 1) * 0.50))]
    let p95 = durations.isEmpty ? 0 : durations[min(durations.count - 1, Int(Double(durations.count - 1) * 0.95))]
    let minValue = durations.first ?? 0
    let maxValue = durations.last ?? 0
    return BKBenchmarkResult(
        name: name,
        iterations: count,
        meanMS: mean,
        p50MS: p50,
        p95MS: p95,
        minMS: minValue,
        maxMS: maxValue,
        samples: samples
    )
}

private func bkMemoryDeltaBytes(before: UInt64?, after: UInt64?) -> UInt64? {
    guard let before, let after else { return nil }
    return after >= before ? after - before : 0
}

private func bkCurrentResidentMemory() -> UInt64? {
    #if canImport(Darwin)
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
    let status: kern_return_t = withUnsafeMutablePointer(to: &info) { ptr in
        ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), intPtr, &count)
        }
    }
    guard status == KERN_SUCCESS else { return nil }
    return UInt64(info.resident_size)
    #else
    return nil
    #endif
}
