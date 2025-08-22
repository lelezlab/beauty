import Foundation

enum LegalFooter {
  static func text(locale: String) -> String {
    switch locale.lowercased() {
      case let s where s.hasPrefix("en"): return "Information only, not medical advice. Procedures may be restricted by local regulations."
      case let s where s.hasPrefix("fr"): return "Informations uniquement, ne constitue pas un avis médical."
      default: return "仅供信息参考，不替代医师诊断与治疗建议。部分术式可能受地区法规限制。"
    }
  }
}


