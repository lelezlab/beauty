import SwiftUI

struct RunAIMetricsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var status: String = "Running..."

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(status).font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
        .onAppear { start() }
        .onDisappear {
            AppFlags.isProofRunning = false
            CaptureStore.shared.lastMesh = nil
        }
    }

    private func start() {
        AppFlags.isProofRunning = true
        ReconstructionOrchestrator.shared.cancelAll()
        Task.detached(priority: .utility) {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let out = docs.appendingPathComponent("proof/ai_metrics", isDirectory: true)
            let mesh: FaceMesh3D? = nil
            let landmarks: [CGPoint]? = nil
            autoreleasepool {
                ProofProducer().produceAIMetricsProof(mesh: mesh, landmarks: landmarks, outDir: out)
            }
            await MainActor.run {
                status = "Done"
                dismiss()
            }
        }
    }
}


