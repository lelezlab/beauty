import Foundation

enum AppConfig {
  static let supabaseBase: String = SupabaseEnv.url
  static let anonKey: String = SupabaseEnv.anonKey
  static var manifestURL: String {
    if let host = URL(string: SupabaseEnv.url)?.host, let ref = host.split(separator: ".").first {
      return "https://\(ref).functions.supabase.co/manifest-sign/latest"
    }
    return ""
  }
}
