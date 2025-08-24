import SwiftUI
import CoreGraphics

struct ProofMenu: View {
    @State private var running = false
    @State private var message: String = ""
    @AppStorage("autoProof") private var autoProof: Bool = false
    @AppStorage("autoShare") private var autoShare: Bool = false

    var body: some View {
        List {
            Section("Debug Flags") {
                Toggle("Force Tri-View", isOn: Binding(get: { AppDebugFlags.forceTriView }, set: { AppDebugFlags.forceTriView = $0 }))
                Toggle("Use Placeholder Edge", isOn: Binding(get: { AppDebugFlags.usePlaceholderEdge }, set: { AppDebugFlags.usePlaceholderEdge = $0 }))
            }
            Section("Generate Proof Pack") {
                Button("Run MockTrueDepth") { Task { await run(.mockTrueDepth) } }.disabled(running)
                Button("Run TriView Placeholder") { Task { await run(.triViewEdgePlaceholder) } }.disabled(running)
                Button("Run BOTH") { Task { await runBoth() } }.disabled(running)
                Button("Run GoldenMask Demo") { Task { await runGolden() } }.disabled(running)
                Button("Run Edge Recon Demo") { Task { let _ = try? await ProofProducer.produceEdgeReconDemo() ; await MainActor.run { message = "Edge Recon Demo done" } } }.disabled(running)
                Button("分享证明材料") { shareProof() }
                if !running && !message.isEmpty { Text("ProofDone").accessibilityIdentifier("ProofDone").hidden() }
            }
            Section("AI Utilities") {
                Button("Warmup AI Providers") { Task { await AIOrchestrator.shared.warmupAll(); await MainActor.run { message = "AI warmed" } } }
                Button("Run AI Metrics") {
                    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let out = docs.appendingPathComponent("proof/ai_metrics", isDirectory: true)
                    let mesh: FaceMesh3D? = nil
                    let landmarks: [CGPoint]? = nil
                    ProofProducer().produceAIMetricsProof(mesh: mesh, landmarks: landmarks, outDir: out)
                    message = "AI metrics generated at \(out.path)"
                }
            }
            Section("Maintenance") {
                Button("导出调试日志") { shareDebugLog() }
                Button("清空调试日志") { DebugLog.clear() }
                Button("Clear ReconCache") { clearReconCache() }
                Button("Re-Fetch Models & Re-Run Edge Demo") { Task { _ = await ModelFetcher.fetchAll(); let _ = try? await ProofProducer.produceEdgeReconDemo(); await MainActor.run { message = "Models fetched & Edge demo regenerated" } } }
            }
            Section("自动化") {
                Toggle("自动运行", isOn: $autoProof)
                Toggle("自动分享", isOn: $autoShare)
                Button("重新获取模型") { Task { _ = await ModelFetcher.fetchAll() } }
            }
            if !message.isEmpty { Text(message).font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationTitle("Proof Pack")
        .onAppear {
            // 种子化本地样片，避免手动拷贝
            ProofSamplesSeeder.seedIfNeeded()
            if autoProof && !running {
                Task { await ProofProducer.runBoth(autoShare: autoShare) }
            }
        }
    }

    private func run(_ mode: ProofMode) async {
        running = true
        let originalForce = AppDebugFlags.forceTriView
        let originalPlaceholder = AppDebugFlags.usePlaceholderEdge
        defer { AppDebugFlags.forceTriView = originalForce; AppDebugFlags.usePlaceholderEdge = originalPlaceholder; running = false }
        if mode == .triViewEdgePlaceholder { AppDebugFlags.forceTriView = true; AppDebugFlags.usePlaceholderEdge = true }
        do {
            let url = try await ProofProducer.run(mode: mode)
            await MainActor.run { message = "Done: \(url.path)" }
        } catch {
            await MainActor.run { message = "Error: \(error.localizedDescription)" }
        }
    }

    private func runBoth() async {
        running = true
        defer { running = false }
        await ProofProducer.runBoth(autoShare: autoShare)
        await MainActor.run { message = "Proof Pack completed." }
    }

    private func runGolden() async {
        running = true
        defer { running = false }
        do {
            let url = try await ProofProducer.runGoldenMaskDemo()
            await MainActor.run { message = "GoldenMask: \(url.path)" }
        } catch {
            await MainActor.run { message = "GoldenMask Error: \(error.localizedDescription)" }
        }
    }

    private func shareProof() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("proof", isDirectory: true)
        let urls = [
            docs.appendingPathComponent("mockTrueDepth/demo.mp4"),
            docs.appendingPathComponent("mockTrueDepth/diagnostics.png"),
            docs.appendingPathComponent("triView/demo.mp4"),
            docs.appendingPathComponent("triView/diagnostics.png"),
            docs.appendingPathComponent("doctor/doctor_mode_demo.mp4")
        ]
        let existing = urls.filter { FileManager.default.fileExists(atPath: $0.path) }
        let av = UIActivityViewController(activityItems: existing, applicationActivities: nil)
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController?.present(av, animated: true)
    }

    private func shareDebugLog() {
        let url = DebugLog.exportURL()
        // Ensure file exists so分享不会失败
        if !FileManager.default.fileExists(atPath: url.path) {
            let data = "(empty)\n".data(using: .utf8)
            try? data?.write(to: url)
        }
        DebugLog.log("shareDebugLog tapped")
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        } else {
            UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController?.present(av, animated: true)
        }
    }

    private func clearReconCache() {
        DispatchQueue.global(qos: .utility).async {
            ReconCache.clearSync()
            DispatchQueue.main.async { message = "ReconCache cleared" }
        }
    }
}


