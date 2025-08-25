import Foundation

struct ClinicalRule: Decodable {
  let id: String
  let metric: String
  let unit: String?
  let soft_min: Double?
  let soft_max: Double?
  let hard_min: Double?
  let hard_max: Double?
}

final class RulesStore {
  static let shared = RulesStore()
  private init() {}
  private(set) var byMetric: [String: ClinicalRule] = [:]

  func fetch() async {
    guard !AppConfig.supabaseBase.contains("<"),
          !AppConfig.anonKey.contains("<") else { return }
    let url = URL(string: "\(AppConfig.supabaseBase)/rest/v1/clinical_rules?select=id,metric,unit,soft_min,soft_max,hard_min,hard_max")!
    var req = URLRequest(url: url)
    req.addValue(AppConfig.anonKey, forHTTPHeaderField: "apikey")
    req.addValue("Bearer \(AppConfig.anonKey)", forHTTPHeaderField: "Authorization")
    do {
      let (data, _) = try await URLSession.shared.data(for: req)
      let items = try JSONDecoder().decode([ClinicalRule].self, from: data)
      self.byMetric = Dictionary(uniqueKeysWithValues: items.map { ($0.metric, $0) })
    } catch {
      print("Rules fetch error:", error.localizedDescription)
    }
  }
}
