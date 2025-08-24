import Foundation

enum RemoteEffectsFlags {
    static var effectsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "ff_effectsEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "ff_effectsEnabled") }
    }
    static var goldenGuidesEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "ff_goldenGuides") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "ff_goldenGuides") }
    }
}


