import SwiftUI

@main
struct BeautyApp: App {
  @StateObject private var results = ResultsStore()
  init() {
    Task { await RulesStore.shared.fetch() }
    MetricKitManager.shared.activate()
    Task.detached {
      guard let u = URL(string: (UserDefaults.standard.string(forKey: "FlagsURL") ?? "")), !u.absoluteString.isEmpty else { return }
      if let (d, _) = try? await URLSession.shared.data(from: u),
         let j = try? JSONSerialization.jsonObject(with: d) as? [String:Any] { AppFeatureFlags.applyRemote(j) }
    }
    Task {
      do {
        _ = try await ManifestService.shared.fetchAndVerifyManifest()
        print("Manifest loaded OK")
      } catch {
        print("Manifest verify failed:", error.localizedDescription)
      }
    }
  }
  var body: some Scene {
    WindowGroup {
      MainTabView()
        .environmentObject(results)
    }
  }
}
