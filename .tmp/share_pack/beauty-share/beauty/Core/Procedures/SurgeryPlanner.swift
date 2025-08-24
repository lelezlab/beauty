import Foundation

struct SurgeryMapping: Codable { let id: String; let name: String; let params: [String: [Double]]; let rules: [String]?; let anatomy: [String]? }

struct SafetyBound { let min: Double; let max: Double; let hardMin: Double?; let hardMax: Double? }

enum SurgeryCatalog {
    static func load() -> [SurgeryMapping] {
        guard let url = Bundle.main.url(forResource: "surgery_catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let arr = try? JSONDecoder().decode([SurgeryMapping].self, from: data) else { return [] }
        return arr
    }
}

enum SurgeryPlanner {
    static func makeParams(for mapping: SurgeryMapping, base: [String: Double], metrics: AestheticsMetrics?) -> [String: Double] {
        var out = base
        for (k, range) in mapping.params {
            let mid = (range.first ?? 0 + (range.last ?? 0))/2.0
            let v = clampToSafety(key: k, value: mid)
            out[k] = v
        }
        return out
    }

    static func safety(for key: String, value: Double) -> (label: String, colorHex: String) {
        guard let w = AestheticsSafetyConfig.recommended[key] else { return ("unknown", "#888888") }
        if value < w.min { return ("soft-low", "#FFA500") }
        if value > w.max { return ("soft-high", "#FFA500") }
        return ("ok", "#00A65A")
    }

    private static func clampToSafety(key: String, value: Double) -> Double {
        if let w = AestheticsSafetyConfig.recommended[key] { return min(max(value, w.min), w.max) }
        return value
    }
}


