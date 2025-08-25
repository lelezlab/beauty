import SwiftUI

@main
struct BeautyApp: App {
  @StateObject private var results = ResultsStore()
  init() {
    Task { await RulesStore.shared.fetch() }
    MetricKitManager.shared.activate()
    // Auto model fetch on launch (zero-interaction)
    Task {
      let ok = await ModelFetcher.fetchAll()
      UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "models_fetch_time")
      UserDefaults.standard.set(ok, forKey: "models_fetch_ok")
    }
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
    Task { await AIOrchestrator.shared.warmupAll() }
  }
  var body: some Scene {
    WindowGroup {
      MainTabView()
        .environmentObject(results)
    }
  }
}
