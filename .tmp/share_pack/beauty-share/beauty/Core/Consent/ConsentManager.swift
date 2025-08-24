import Foundation
final class ConsentManager {
  static let shared = ConsentManager()
  private let k = "user_consent_v1"
  enum State: String { case unknown, accepted, declined }
  var state: State {
    get { State(rawValue: UserDefaults.standard.string(forKey: k) ?? "unknown") ?? .unknown }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: k) }
  }
}


