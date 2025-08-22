import Foundation
import CoreGraphics

struct GeometrySuggestion { let title: String; let detail: String; let severity: String }

enum GeometryAnalyzer {
    // Placeholder computations
    static func nasolabialAngleDeg(nasion: CGPoint, subnasale: CGPoint, labialeSuperius: CGPoint) -> Double? {
        let v1 = CGPoint(x: nasion.x - subnasale.x, y: nasion.y - subnasale.y)
        let v2 = CGPoint(x: labialeSuperius.x - subnasale.x, y: labialeSuperius.y - subnasale.y)
        let dot = Double(v1.x*v2.x + v1.y*v2.y)
        let m1 = sqrt(Double(v1.x*v1.x + v1.y*v1.y))
        let m2 = sqrt(Double(v2.x*v2.x + v2.y*v2.y))
        guard m1 > 1e-6, m2 > 1e-6 else { return nil }
        return acos(max(-1,min(1,dot/(m1*m2)))) * 180.0 / .pi
    }

    static func goodeRatio(tipProjection: Double, nasalLength: Double) -> Double? {
        guard nasalLength > 1e-6 else { return nil }
        return tipProjection / nasalLength
    }

    static func suggestions(from metrics: [String: Double]) -> [GeometrySuggestion] {
        var out: [GeometrySuggestion] = []
        if let nla = metrics["nasolabial"], nla < 95 { out.append(.init(title: "鼻尖旋转", detail: "建议 +2–4°，改善鼻唇角 (当前 \(Int(nla))°)", severity: "soft")) }
        if let gr = metrics["goode"], gr < 0.52 { out.append(.init(title: "鼻尖前移", detail: "建议 +1–3mm，Goode=\(String(format: "%.2f", gr))", severity: "soft")) }
        return out
    }
}


