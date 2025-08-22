import SwiftUI

struct Face3DPreviewView: View {
    @State private var meshAvailable: Bool = CaptureStore.shared.lastMesh != nil
    @State private var isComputing: Bool = false
    @State private var t1: Double = 1.0
    @State private var t2: Double = 3.0
    @State private var alpha: Double = 0.95
    @State private var showWireframe: Bool = false
    @State private var showTexture: Bool = true
    @State private var beforeAfter: Double = 0.0 // 0 = before, 1 = after (hook)

    var body: some View {
        VStack(spacing: 12) {
            if meshAvailable, let m = CaptureStore.shared.lastMesh {
                GoldenMask3DOverlay(mesh: m, t1: Float(t1), t2: Float(t2), alpha: Float(alpha))
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
                Toggle("线框", isOn: $showWireframe).toggleStyle(.switch)
                Toggle("纹理", isOn: $showTexture).toggleStyle(.switch)
            }
            // 热力与透明度设置
            Group {
                HStack { Text("绿≤"); Slider(value: $t1, in: 0.5...2.0); Text(String(format: "%.1fmm", t1)) }
                HStack { Text("黄≤"); Slider(value: $t2, in: 2.0...5.0); Text(String(format: "%.1fmm", t2)) }
                HStack { Text("透明度"); Slider(value: $alpha, in: 0.2...1.0); Text(String(format: "%.2f", alpha)) }
                HStack { Text("术前↔术后"); Slider(value: $beforeAfter, in: 0...1) }
            }
            .font(.caption)
            .padding(.horizontal, 4)
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


