import SwiftUI
import ARKit

struct DiagnosticsView: View {
  @State private var arkit: Bool = ARFaceTrackingConfiguration.isSupported
  @State private var framesCached: Bool = ARFaceGeometryCache.shared.lastGeometry != nil
  @State private var lastReconOK: Bool = UserDefaults.standard.bool(forKey: "last_recon_ok")
  @State private var modelsLoaded: Bool = false
  @State private var facemeshStatus: String = "-"
  @State private var arcfaceStatus: String = "-"
  @State private var parsingStatus: String = "-"
  @State private var midasStatus: String = "-"
  @State private var lastFetchOK: Bool = UserDefaults.standard.bool(forKey: "models_fetch_ok")
  @State private var tier: PerfTier = AIRouter.tier()
  @State private var useEdgeRecon: Bool = AIRouter.useEdge(for: .reconstruction3D)
  @State private var useEdgeParsing: Bool = AIRouter.useEdge(for: .faceParsing)
  @State private var useEdgeDepth: Bool = AIRouter.useEdge(for: .midasDepth)
  @State private var lastFPS: Double = UserDefaults.standard.double(forKey: "ai_last_fps")
  @State private var lastLatency: Double = UserDefaults.standard.double(forKey: "ai_last_latency_ms")
  @State private var lastThermalSerious: Bool = UserDefaults.standard.bool(forKey: "ai_last_thermal_serious")
  @State private var maskOverlayOK: Bool = true
  @State private var parsingOK: Bool = true
  @State private var depthOK: Bool = true
  @State private var unitsOK: Bool = true
  @State private var edgeProvider: String = (UserDefaults.standard.string(forKey: "edge_provider") ?? "mock")
  @State private var edgeLast: Bool = UserDefaults.standard.bool(forKey: "edge_last_ok")
  @State private var edgeJobId: String = (UserDefaults.standard.string(forKey: "edge_job_id") ?? "-")
  @State private var edgeLastResult: String = (UserDefaults.standard.string(forKey: "edge_last_result") ?? "-")
  @State private var edgeCachePath: String = {
    if let id = UserDefaults.standard.string(forKey: "edge_job_id"), !id.isEmpty {
      let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      return base.appendingPathComponent("ReconCache/\(id)").path
    }
    return "-"
  }()
  @State private var edgeLatencyMs: Double = UserDefaults.standard.double(forKey: "edge_latency_ms")
  @State private var edgeGLBSize: Int = UserDefaults.standard.integer(forKey: "edge_glb_size")
  @State private var edgeTexSize: Int = UserDefaults.standard.integer(forKey: "edge_tex_size")
  @State private var edgeErrDomain: String = (UserDefaults.standard.string(forKey: "edge_error_domain") ?? "-")
  @State private var edgeErrMessage: String = (UserDefaults.standard.string(forKey: "edge_error_message") ?? "-")

  var body: some View {
    List {
      Section("Runtime") {
        rowBool("ARKit available", arkit)
        rowBool("Face frames cached", framesCached)
        rowBool("Last reconstruction ok", lastReconOK)
      }
      Section("Mask/Parsing/Depth") {
        rowBool("Mask overlay", maskOverlayOK)
        rowBool("Parsing", parsingOK)
        rowBool("Depth", depthOK)
        rowBool("Units (mm→m)", unitsOK)
      }
      Section("Edge Provider") {
        copyRow("Edge provider", edgeProvider)
        copyRow("Edge job id", edgeJobId)
        copyRow("Edge last_result", edgeLastResult)
        copyRow("Edge cache path", edgeCachePath)
        copyRow("Edge latency(ms)", String(format: "%.0f", edgeLatencyMs))
        copyRow("GLB size(bytes)", String(edgeGLBSize))
        copyRow("Texture size(bytes)", String(edgeTexSize))
        copyRow("Edge error", edgeErrDomain + ": " + edgeErrMessage)
      }
      Section("Models") {
        rowBool("Models lock loaded", modelsLoaded)
        rowText("facemesh_mediapipe_task", facemeshStatus)
        rowText("arcface_ir50", arcfaceStatus)
        rowText("face_parsing_bisenet", parsingStatus)
        rowText("midas_s", midasStatus)
        rowBool("Last Re-Fetch ok", lastFetchOK)
        Button("Re-Fetch Models (mirror)") { Task { _ = await ModelFetcher.fetchAll(); UserDefaults.standard.set(Date(), forKey: "models_refetch_ts"); refresh() } }
      }
      Section("AI Router") {
        HStack { Text("Perf tier"); Spacer(); Text(tier.rawValue) }
        rowBool("Edge: 3D Recon", useEdgeRecon)
        rowBool("Edge: Face Parsing", useEdgeParsing)
        rowBool("Edge: Depth", useEdgeDepth)
        HStack { Text("Last FPS"); Spacer(); Text(String(format: "%.1f", lastFPS)) }
        HStack { Text("Last Latency (ms)"); Spacer(); Text(String(format: "%.0f", lastLatency)) }
        rowBool("Thermal serious", lastThermalSerious)
      }
    }
    .navigationTitle("Diagnostics")
    .onAppear { refresh() }
  }

  private func refresh() {
    arkit = ARFaceTrackingConfiguration.isSupported
    framesCached = ARFaceGeometryCache.shared.lastGeometry != nil
    lastReconOK = UserDefaults.standard.bool(forKey: "last_recon_ok")
    // lock existence
    modelsLoaded = (Bundle.main.url(forResource: "models.lock", withExtension: "json", subdirectory: "Resources/Models") != nil) || (Bundle.main.url(forResource: "models.lock", withExtension: "json", subdirectory: "Models") != nil)
    facemeshStatus = statusFor("facemesh_mediapipe_task")
    arcfaceStatus = statusFor("arcface_ir50")
    parsingStatus = statusFor("face_parsing_bisenet")
    midasStatus = statusFor("midas_s")
    lastFetchOK = UserDefaults.standard.bool(forKey: "models_fetch_ok")
    tier = AIRouter.tier()
    useEdgeRecon = AIRouter.useEdge(for: .reconstruction3D)
    useEdgeParsing = AIRouter.useEdge(for: .faceParsing)
    useEdgeDepth = AIRouter.useEdge(for: .midasDepth)
    lastFPS = UserDefaults.standard.double(forKey: "ai_last_fps")
    lastLatency = UserDefaults.standard.double(forKey: "ai_last_latency_ms")
    lastThermalSerious = UserDefaults.standard.bool(forKey: "ai_last_thermal_serious")
    edgeProvider = (UserDefaults.standard.string(forKey: "edge_provider") ?? edgeProvider)
    edgeJobId = (UserDefaults.standard.string(forKey: "edge_job_id") ?? edgeJobId)
    edgeLastResult = (UserDefaults.standard.string(forKey: "edge_last_result") ?? edgeLastResult)
    edgeLatencyMs = UserDefaults.standard.double(forKey: "edge_latency_ms")
    edgeGLBSize = UserDefaults.standard.integer(forKey: "edge_glb_size")
    edgeTexSize = UserDefaults.standard.integer(forKey: "edge_tex_size")
    edgeErrDomain = (UserDefaults.standard.string(forKey: "edge_error_domain") ?? edgeErrDomain)
    edgeErrMessage = (UserDefaults.standard.string(forKey: "edge_error_message") ?? edgeErrMessage)
  }

  private func statusFor(_ id: String) -> String {
    do { _ = try ModelRegistry.path(for: id); return "ok" }
    catch let e as ModelError {
      switch e {
      case .fileMissing: return "missing"
      case .hashMismatch: return "hashMismatch"
      default: return "error"
      }
    } catch { return "error" }
  }

  private func rowBool(_ title: String, _ ok: Bool) -> some View {
    HStack { Text(title); Spacer(); Image(systemName: ok ? "checkmark.seal.fill" : "xmark.seal.fill").foregroundStyle(ok ? .green : .red) }
  }
  private func rowText(_ title: String, _ value: String) -> some View {
    HStack { Text(title); Spacer(); Text(value).foregroundStyle(value == "ok" ? .green : (value == "missing" ? .orange : .red)).font(.subheadline) }
  }
  private func copyRow(_ title: String, _ value: String) -> some View {
    HStack { Text(title); Spacer(); Text(value).font(.footnote).textSelection(.enabled) }
      .contentShape(Rectangle())
      .onTapGesture { UIPasteboard.general.string = value }
  }
}


