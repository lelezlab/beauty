import Foundation

enum AppDebugFlags {
    static var forceTriView: Bool {
        get { UserDefaults.standard.bool(forKey: "dbg_force_tri_view") }
        set { UserDefaults.standard.set(newValue, forKey: "dbg_force_tri_view") }
    }
}


