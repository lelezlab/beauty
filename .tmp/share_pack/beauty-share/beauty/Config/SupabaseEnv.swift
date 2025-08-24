import Foundation

enum SupabaseEnv {
    static var url: String { (Bundle.main.infoDictionary?["SUPABASE_URL"] as? String) ?? "" }
    static var anonKey: String { (Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String) ?? "" }
}


