import SwiftUI

struct ProofMenu: View {
    @State private var running = false
    @State private var message: String = ""

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
                Button("分享证明材料") { shareProof() }
                if !running && !message.isEmpty { Text("ProofDone").accessibilityIdentifier("ProofDone").hidden() }
            }
            if !message.isEmpty { Text(message).font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationTitle("Proof Pack")
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
        do { try await run(.mockTrueDepth); try await run(.triViewEdgePlaceholder); await MainActor.run { shareProof() } } catch {}
    }

    private func shareProof() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("proof", isDirectory: true)
        let urls = [
            docs.appendingPathComponent("mockTrueDepth/demo.mp4"),
            docs.appendingPathComponent("mockTrueDepth/diagnostics.png"),
            docs.appendingPathComponent("triView/demo.mp4"),
            docs.appendingPathComponent("triView/diagnostics.png")
        ]
        let av = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController?.present(av, animated: true)
    }
}


