import SwiftUI

@main
struct BeautyApp: App {
  @StateObject private var results = ResultsStore()
  init() {
    Task { await RulesStore.shared.fetch() }
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
