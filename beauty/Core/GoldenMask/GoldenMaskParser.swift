import Foundation
import CoreGraphics

struct GoldenAnchor: Decodable { let name: String; let type: String; let desc: String? }
struct GoldenCurve: Decodable { let name: String; let through: [String]; let smoothing: Double? }
struct GoldenTargets: Decodable { let param: String; let metric: String; let soft: [Double]?; let hard: [Double]? }
struct GoldenSpec: Decodable { let version: Int; let unit: String; let scale_mm_per_px: Double?; let anchors: [GoldenAnchor]; let curves: [GoldenCurve]?; let targets: [GoldenTargets]? }

enum GoldenMaskParser {
    static func loadSpec(from url: URL) -> GoldenSpec? {
        if let data = try? Data(contentsOf: url) { return try? JSONDecoder().decode(GoldenSpec.self, from: data) }
        return nil
    }
}


