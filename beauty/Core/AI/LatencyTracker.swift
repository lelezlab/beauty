import Foundation

enum LatencyTracker {
    private static var lock = NSLock()
    private static var map: [String: [Double]] = [:] // ms samples
    private static let maxSamples = 200

    static func addSample(_ ms: Double, key: String) {
        lock.lock(); defer { lock.unlock() }
        var arr = map[key] ?? []
        arr.append(ms)
        if arr.count > maxSamples { arr.removeFirst(arr.count - maxSamples) }
        map[key] = arr
    }

    static func snapshot() -> [String: [String: Double]] {
        lock.lock(); let copy = map; lock.unlock()
        var out: [String: [String: Double]] = [:]
        for (k, arr) in copy {
            guard !arr.isEmpty else { continue }
            let sorted = arr.sorted()
            func pct(_ p: Double) -> Double { // p in [0,1]
                let i = Int(Double(sorted.count-1) * p)
                return sorted[max(0, min(i, sorted.count-1))]
            }
            out[k] = [
                "count": Double(sorted.count),
                "p50_ms": pct(0.5),
                "p95_ms": pct(0.95),
                "max_ms": sorted.last ?? 0,
                "min_ms": sorted.first ?? 0
            ]
        }
        return out
    }
}


