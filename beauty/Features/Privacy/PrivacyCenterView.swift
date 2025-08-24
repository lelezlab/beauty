import SwiftUI

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PrivacyCenterView: View {
    @AppStorage("privacy_local_first") private var localFirst: Bool = true
    @AppStorage("privacy_allow_edge") private var allowEdge: Bool = false
    @AppStorage("privacy_share_deid") private var shareDeId: Bool = false
    @AppStorage("telemetry_crash") private var telemetryCrash: Bool = true
    @AppStorage("telemetry_perf") private var telemetryPerf: Bool = true
    @AppStorage("telemetry_events") private var telemetryEvents: Bool = false

    @State private var showExportSheet = false
    @State private var exportURL: URL? = nil

    var body: some View {
        List {
            Section("隐私中心") {
                Toggle("本地处理优先", isOn: $localFirst)
                Toggle("允许远端处理", isOn: $allowEdge)
                Toggle("分享去标识化数据以改进产品", isOn: $shareDeId)
            }
            Section("数据管理") {
                Button("导出本地数据 ZIP") { exportZip() }
                Button("清空全部本地数据", role: .destructive) { clearAll() }
            }
            Section("遥测与日志") {
                Toggle("崩溃日志", isOn: $telemetryCrash)
                Toggle("性能指标", isOn: $telemetryPerf)
                Toggle("使用事件（匿名）", isOn: $telemetryEvents)
            }
            Section("法律") {
                Text("非医疗建议：本应用输出仅供美学参考，不构成医疗诊断或治疗。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("隐私中心")
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL { ActivityView(items: [url]) }
        }
    }

    private func exportZip() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let zip = docs.appendingPathComponent("sessions.zip")
        // 简化：打包 proof 目录以示例
        _ = ProofZipper.zip(at: docs.appendingPathComponent("proof"), to: zip)
        exportURL = zip; showExportSheet = true
    }

    private func clearAll() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if let items = try? FileManager.default.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil) {
            for u in items { try? FileManager.default.removeItem(at: u) }
        }
    }
}


