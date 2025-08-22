import Foundation

struct SurgeryMapping: Codable { let id: String; let name: String; let params: [String: [Double]]; let rules: [String]?; let anatomy: [String]? }

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
            let v = clampToSafety(key: k, value: (range.first ?? 0 + (range.last ?? 0))/2.0)
            out[k] = v
        }
        // TODO: 使用 clinical rules 做软/硬边界裁剪（占位已在 clampToSafety 处理推荐范围）
        return out
    }

    private static func clampToSafety(key: String, value: Double) -> Double {
        if let w = AestheticsSafetyConfig.recommended[key] { return min(max(value, w.min), w.max) }
        return value
    }
}


