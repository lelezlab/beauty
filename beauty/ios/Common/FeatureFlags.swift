import Foundation

enum FeatureFlags {
  static var enableDynamicVideo = true
  static var enable3DPreview = true
  static var enableClinicianMode = true
  static var enableSafetyBanner = true
  static var enableAB = true
  static var enableDiagnostics = true

  static func applyRemote(_ json: [String: Any]) {
    func b(_ k:String,_ d: inout Bool){ if let v = json[k] as? Bool { d = v } }
    b("enableDynamicVideo", &enableDynamicVideo)
    b("enable3DPreview", &enable3DPreview)
    b("enableClinicianMode", &enableClinicianMode)
    b("enableSafetyBanner", &enableSafetyBanner)
    b("enableAB", &enableAB)
    b("enableDiagnostics", &enableDiagnostics)
  }
}


