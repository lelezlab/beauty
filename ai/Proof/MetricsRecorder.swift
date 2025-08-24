import Foundation

public final class MetricsRecorder {
    public static func writeMetrics(_ measures: FacialMeasures,
                                    hits: [RuleHit],
                                    to dir: URL) throws {
        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let mData = try enc.encode(measuresJSON(measures))
        try mData.write(to: dir.appendingPathComponent("metrics.json"))
        let hData = try enc.encode(hits)
        try hData.write(to: dir.appendingPathComponent("rules_hits.json"))
    }

    private static func measuresJSON(_ m: FacialMeasures) -> [String: Double] {
        var d: [String: Double] = [:]
        if let v = m.nasolabialAngleDeg { d["nasolabial_angle"] = Double(v) }
        if let v = m.mentocervicalAngleDeg { d["mentocervical_angle"] = Double(v) }
        if let v = m.intercanthalToEyeWidth { d["intercanthal_to_eye_width"] = Double(v) }
        return d
    }
}


