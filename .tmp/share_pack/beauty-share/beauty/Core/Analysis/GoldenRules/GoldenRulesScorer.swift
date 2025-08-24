import Foundation

struct GoldenRuleRange: Codable { let min: Double; let max: Double; let weight: Double }
struct GoldenRulesConfig: Codable {
    let nasolabialFemale: GoldenRuleRange
    let nasolabialMale: GoldenRuleRange
    let nasofrontal: GoldenRuleRange
    let fiveEyes: GoldenRuleRange
    let threeZones: GoldenRuleRange
}

struct GoldenRulesScore: Codable {
    let total: Double
    let details: [String: Double]
}

enum GoldenRulesScorer {
    static func score(metrics: FacialMetrics, config: GoldenRulesConfig, isFemale: Bool) -> GoldenRulesScore {
        var total = 0.0
        var weightSum = 0.0
        var details: [String: Double] = [:]

        func clampScore(value: Double?, range: GoldenRuleRange, key: String) {
            guard let v = value else { return }
            let s: Double
            if v < range.min { s = max(0, 1 - (range.min - v)/(range.max - range.min)) }
            else if v > range.max { s = max(0, 1 - (v - range.max)/(range.max - range.min)) }
            else { s = 1.0 }
            total += s * range.weight
            weightSum += range.weight
            details[key] = s
        }

        clampScore(value: metrics.nasolabialDeg, range: isFemale ? config.nasolabialFemale : config.nasolabialMale, key: "nasolabial")
        clampScore(value: metrics.nasofrontalDeg, range: config.nasofrontal, key: "nasofrontal")
        clampScore(value: metrics.fiveEyes, range: config.fiveEyes, key: "fiveEyes")
        clampScore(value: metrics.threeZones, range: config.threeZones, key: "threeZones")
        if let sym = metrics.symmetry { total += sym * 0.5; weightSum += 0.5; details["symmetry"] = sym }
        let final = weightSum > 0 ? total/weightSum : 0
        return GoldenRulesScore(total: final, details: details)
    }
}


