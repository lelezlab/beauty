import Foundation

enum SupabaseConfig {
    static var url: URL? {
        if let s = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String, let u = URL(string: s) { return u }
        if let s = ProcessInfo.processInfo.environment["SUPABASE_URL"], let u = URL(string: s) { return u }
        if let s = UserDefaults.standard.string(forKey: "SUPABASE_URL"), let u = URL(string: s) { return u }
        return nil
    }
    static var anonKey: String? {
        if let s = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String { return s }
        if let s = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] { return s }
        if let s = UserDefaults.standard.string(forKey: "SUPABASE_ANON_KEY") { return s }
        return nil
    }
}


