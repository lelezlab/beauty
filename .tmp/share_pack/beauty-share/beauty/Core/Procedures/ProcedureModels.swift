import Foundation

struct Procedure: Codable, Identifiable {
    let id: String
    let category: String // e.g., "nose", "chin"
    let name: String
    let summary: String
    let principles: [String]
    let risks: [String]
    let recoveryDays: Int
    let budgetUSD: [Int] // [min, max]
    let effectStability: Int // 1..5
    let invasiveness: Int // 1..5
    let evidenceLevel: String // e.g., "A", "B"
    // 扩展信息（可选）
    let contraindications: [String]?
    let aftercare: [String]?
    let budgetNotes: [String]?
    let questionChecklist: [String]?
}

enum ProcedureStore {
    static func loadAll() -> [Procedure] {
        // 根据手动语言设置或系统语言选择资源优先级：中文→法语→US
        let preferred: [String] = {
            let manual = UserDefaults.standard.string(forKey: "app.language.code") ?? ""
            let sys = Locale.current.identifier
            let lang = manual.isEmpty ? sys : manual
            if lang.hasPrefix("zh") { return ["procedures_cn", "procedures_fr", "procedures_us"] }
            if lang.hasPrefix("fr") { return ["procedures_fr", "procedures_us"] }
            return ["procedures_us"]
        }()
        for name in preferred {
            if let url = Bundle.main.url(forResource: name, withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let arr = try? JSONDecoder().decode([Procedure].self, from: data) {
                return arr
            }
        }
        return []
    }

    static func byCategory(_ category: String) -> [Procedure] {
        return loadAll().filter { $0.category == category }
    }
}


