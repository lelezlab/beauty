import Foundation
import CoreGraphics

// Lightweight bridges to satisfy the App target.
// Full-featured implementations live under ai/ and can replace these later.

public struct FacialMeasures: Codable {
    public var nasolabialAngleDeg: Float?
    public var mentocervicalAngleDeg: Float?
    public var intercanthalToEyeWidth: Float?
}

public enum MeasureQuality: String, Codable { case good, fair, poor }

public struct MeasurementResult: Codable {
    public let measures: FacialMeasures
    public let quality: MeasureQuality
    public let notes: [String]
}

public enum FacialAnthroKit {
    public static func measureFrom(mesh: FaceMesh3D?, landmarks: [CGPoint]?) -> MeasurementResult {
        // Minimal placeholder values to keep pipeline functional in App target
        var m = FacialMeasures()
        m.nasolabialAngleDeg = 95
        m.mentocervicalAngleDeg = 90
        m.intercanthalToEyeWidth = 1.0
        return MeasurementResult(measures: m, quality: .fair, notes: [])
    }
}

public struct RuleHit: Codable {
    public let id: String
    public let title: String
    public let message: String
    public let severity: String
    public let citations: [String]
    public let value: Double?
    public let refRange: String?
}

public final class RulesEngine {
    public struct Context {
        public let gender: String?
        public let age: Int?
        public let ethnicity: String?
        public init(gender: String?, age: Int?, ethnicity: String?) {
            self.gender = gender; self.age = age; self.ethnicity = ethnicity
        }
    }
    public init(rulesURL: URL, refsURL: URL) throws { /* no-op bridge */ }
    public func evaluate(measures: FacialMeasures, ctx: Context) -> [RuleHit] { return [] }
}

public final class MetricsRecorder {
    public static func writeMetrics(_ measures: FacialMeasures, hits: [RuleHit], to dir: URL) throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        let mData = try enc.encode(measuresDictionary(measures))
        try mData.write(to: dir.appendingPathComponent("metrics.json"))
        let hData = try enc.encode(hits)
        try hData.write(to: dir.appendingPathComponent("rules_hits.json"))
    }
    private static func measuresDictionary(_ m: FacialMeasures) -> [String: Double] {
        var d: [String: Double] = [:]
        if let v = m.nasolabialAngleDeg { d["nasolabial_angle"] = Double(v) }
        if let v = m.mentocervicalAngleDeg { d["mentocervical_angle"] = Double(v) }
        if let v = m.intercanthalToEyeWidth { d["intercanthal_to_eye_width"] = Double(v) }
        return d
    }
}


