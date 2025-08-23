import SwiftUI
import ARKit

struct DiagnosticsView: View {
  @State private var manifestOK: Bool? = nil
  @State private var rulesOK: Bool? = nil
  @State private var kbOK: Bool? = nil
  @State private var messages: [String] = []

  var body: some View {
    List {
      Section("Connectivity") {
        row("Manifest /latest", manifestOK)
        row("Clinical Rules", rulesOK)
        row("KB Docs", kbOK)
        HStack { Text("ARKit available"); Spacer(); Text(ARFaceTrackingConfiguration.isSupported ? "true" : "false").foregroundStyle(.secondary) }
        HStack { Text("Face frames cached"); Spacer(); Text(ARFaceGeometryCache.shared.lastGeometry == nil ? "false" : "true").foregroundStyle(.secondary) }
        HStack { Text("Last reconstruction"); Spacer(); Text(UserDefaults.standard.bool(forKey: "last_recon_ok") ? "ok" : "-").foregroundStyle(.secondary) }
      }
      Section("Logs") {
        ForEach(messages, id:\.self) { Text($0).font(.footnote).foregroundStyle(.secondary) }
      }
      Button("Run All Checks") { Task { await runChecks() } }
    }
    .navigationTitle("Diagnostics")
    .onAppear { if AppFeatureFlags.enableDiagnostics { Task { await runChecks() } } }
  }

  func row(_ title: String, _ ok: Bool?) -> some View {
    HStack { Text(title)
      Spacer()
      if ok == nil { ProgressView() }
      else if ok == true { Image(systemName: "checkmark.seal.fill").foregroundStyle(.green) }
      else { Image(systemName: "xmark.seal.fill").foregroundStyle(.red) }
    }
  }

  func log(_ s:String){ DispatchQueue.main.async { messages.append(s) } }

  func runChecks() async {
    messages.removeAll()
    // Manifest
    if let u = URL(string: AppConfig.manifestURL), !AppConfig.manifestURL.contains("<") {
      do { let (_, r) = try await URLSession.shared.data(from: u); manifestOK = (r as? HTTPURLResponse)?.statusCode == 200; log("Manifest status: \((r as? HTTPURLResponse)?.statusCode ?? -1)") }
      catch { manifestOK = false; log("Manifest error: \(error.localizedDescription)") }
    } else { manifestOK = false; log("Manifest URL not configured") }

    // Rules
    if !AppConfig.supabaseBase.contains("<") {
      do {
        var req = URLRequest(url: URL(string: "\(AppConfig.supabaseBase)/rest/v1/clinical_rules?select=id&limit=1")!)
        req.addValue(AppConfig.anonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(AppConfig.anonKey)", forHTTPHeaderField: "Authorization")
        let (_, r) = try await URLSession.shared.data(for: req)
        rulesOK = (r as? HTTPURLResponse)?.statusCode == 200; log("Rules status: \((r as? HTTPURLResponse)?.statusCode ?? -1)")
      } catch { rulesOK = false; log("Rules error: \(error.localizedDescription)") }
    } else { rulesOK = false; log("Supabase not configured") }

    // KB
    if !AppConfig.supabaseBase.contains("<") {
      do {
        let url = URL(string:"\(AppConfig.supabaseBase)/rest/v1/kb_docs?select=id&limit=1")!
        var req = URLRequest(url:url)
        req.addValue(AppConfig.anonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(AppConfig.anonKey)", forHTTPHeaderField: "Authorization")
        let (_, r) = try await URLSession.shared.data(for: req)
        kbOK = (r as? HTTPURLResponse)?.statusCode == 200; log("KB status: \((r as? HTTPURLResponse)?.statusCode ?? -1)")
      } catch { kbOK = false; log("KB error: \(error.localizedDescription)") }
    } else { kbOK = false }
  }
}


