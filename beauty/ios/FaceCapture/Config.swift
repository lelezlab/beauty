import Foundation

enum FaceCaptureConfig {
    static var restBase: String { SupabaseEnv.url }
    static var functionsBase: String { SupabaseEnv.url + "/functions/v1" }
    static var manifestURL: String { UserDefaults.standard.string(forKey: "manifest_url") ?? "" }
}


