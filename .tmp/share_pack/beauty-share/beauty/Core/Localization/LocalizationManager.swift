import Foundation
import SwiftUI

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published private(set) var languageCode: String? // e.g. "en", "zh-Hans", "fr"; nil = follow system

    private let storageKey = "app.language.code"

    init() {
        languageCode = UserDefaults.standard.string(forKey: storageKey)
    }

    func setLanguage(code: String?) {
        languageCode = code
        if let code { UserDefaults.standard.set(code, forKey: storageKey) } else { UserDefaults.standard.removeObject(forKey: storageKey) }
        objectWillChange.send()
    }

    var bundle: Bundle {
        guard let code = languageCode,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let b = Bundle(path: path) else { return .main }
        return b
    }

    func text(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

struct LocalizedText: View {
    @EnvironmentObject private var i18n: LocalizationManager
    let key: String

    init(_ key: String) { self.key = key }

    var body: some View { Text(i18n.text(key)) }
}


