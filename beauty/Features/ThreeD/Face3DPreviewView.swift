import SwiftUI

struct Face3DPreviewView: View {
    @State private var meshAvailable: Bool = CaptureStore.shared.lastMesh != nil
    @State private var isComputing: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            if meshAvailable, let m = CaptureStore.shared.lastMesh {
                GoldenMask3DOverlay(mesh: m)
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 220)
                    .overlay(Text("暂无 3D 网格，点击下方生成或先在‘面诊→动态’完成三帧采集").font(.footnote).foregroundStyle(.secondary).padding())
            }
            HStack {
                Button(meshAvailable ? "重新生成" : "生成 3D 预览") {
                    Task { await reconstructIfPossible() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isComputing)
                if isComputing { ProgressView().padding(.leading, 6) }
                Spacer()
            }
            Text("说明：当前为占位 3D 预览（示例球体）。真机将优先使用 ARKit 网格；无 TrueDepth 时将回退到轻量拟合。")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("3D 预览（实验）")
        .onAppear { meshAvailable = CaptureStore.shared.lastMesh != nil }
    }

    private func reconstructIfPossible() async {
        isComputing = true
        defer { isComputing = false }
        let _ = await ReconstructionOrchestrator.shared.reconstruct(backend: .arkit)
        await MainActor.run { meshAvailable = CaptureStore.shared.lastMesh != nil }
    }
}


