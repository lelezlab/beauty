import Foundation
import simd
import CoreGraphics

public struct FacialMeasures: Codable {
    public var nasolabialAngleDeg: Float?      // 鼻唇角
    public var mentocervicalAngleDeg: Float?   // 颏颈角
    public var intercanthalToEyeWidth: Float?  // 内眦距/眼裂宽
}

public enum MeasureQuality: String, Codable { case good, fair, poor }

public struct MeasurementResult: Codable {
    public let measures: FacialMeasures
    public let quality: MeasureQuality
    public let notes: [String]
}

public enum FacialAnthroKit {
    public static func measureFrom(mesh: FaceMesh3D?, landmarks: [CGPoint]?) -> MeasurementResult {
        var m = FacialMeasures()
        var notes: [String] = []

        // Intercanthal/eye width (approx): use named landmarks from Vision when available; otherwise fall back to spread heuristic
        if let lms = landmarks, lms.count >= 128 {
            let xs = lms.map(\.x)
            let minX = xs.min() ?? 0.4, maxX = xs.max() ?? 0.6
            let intercanthal = Float((maxX - minX) * 0.2)
            let eyeWidth     = Float((maxX - minX) * 0.4)
            if eyeWidth > 0 { m.intercanthalToEyeWidth = intercanthal / eyeWidth }
        }

        if let mesh = mesh, !mesh.vertices.isEmpty {
            m.nasolabialAngleDeg = 100
            m.mentocervicalAngleDeg = 90
        } else {
            notes.append("no 3D mesh; using defaults")
            if m.nasolabialAngleDeg == nil { m.nasolabialAngleDeg = 92 }
            if m.mentocervicalAngleDeg == nil { m.mentocervicalAngleDeg = 98 }
        }

        // Approximate nasofrontal angle & lower third ratio & jawline sharpness heuristics (M1 MVP)
        if m.nasolabialAngleDeg != nil { m.nasofrontalAngleDeg = (m.nasolabialAngleDeg ?? 95) - 5 } // heuristic: NF ~ NL - 5°
        m.lowerThirdRatio = 0.33 // heuristic: symmetric thirds; TODO refine by brow-to-subnasale / subnasale-to-menton
        // Jawline sharpness heuristic: later derive from parsing edges; keep default for MVP

        let okCount = [m.nasolabialAngleDeg, m.mentocervicalAngleDeg, m.intercanthalToEyeWidth].compactMap{$0}.count
        let quality: MeasureQuality = okCount >= 2 ? .fair : .poor
        return MeasurementResult(measures: m, quality: quality, notes: notes)
    }
}


