import Foundation

final class ABManager {
    static let shared = ABManager()
    private let key = "ab_bucket"
    var currentBucket: String {
        if let b = UserDefaults.standard.string(forKey: key) { return b }
        let b = Bool.random() ? "A" : "B"
        UserDefaults.standard.set(b, forKey: key)
        return b
    }
}


