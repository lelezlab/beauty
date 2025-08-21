import SwiftUI

struct EffectsGalleryView: View {
    @StateObject private var center = EffectCenter.shared
    @State private var manifestURL: String = "https://example.com/manifest.json"

    var body: some View {
        List {
            Section("远程清单") {
                HStack { TextField("Manifest URL", text: $manifestURL).textInputAutocapitalization(.never); Button("拉取") { Task { try? await center.fetchManifest(from: URL(string: manifestURL)!); await center.syncEffects(deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "dev", appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0", regionCode: Locale.current.region?.identifier ?? "US") } } }
            }

            Section("效果列表") {
                ForEach(center.activeEffects) { pack in
                    NavigationLink(pack.display_name) { EffectDetailView(pack: pack) }
                }
            }
        }
        .navigationTitle("效果中心")
    }
}

struct EffectDetailView: View {
    let pack: EffectPack
    @State private var controlValues: [String: Double] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(pack.display_name).font(.title3).bold()
                Text("免责声明：仅为视觉模拟，非医疗建议。").font(.footnote).foregroundStyle(.secondary)
                HStack { Button("一键参考黄金法则") { /* TODO: 调用 AestheticsMetrics 生成建议并映射到 controlValues */ } }
                ForEach(pack.controls) { c in
                    VStack(alignment: .leading) {
                        HStack { Text(c.key); Spacer(); Text(String(format: "%.2f", controlValues[c.key] ?? (c.default ?? 0))) }
                        if let r = c.range, r.count == 2 { Slider(value: Binding(get: { controlValues[c.key] ?? (c.default ?? 0) }, set: { controlValues[c.key] = $0 }), in: r[0]...r[1]) }
                    }
                }
                // 占位预览图
                RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)).frame(height: 220).overlay(Text("预览占位：实际渲染管线接入 EffectComposer"))
                Button("记录此次效果使用") {
                    let effect = BTEffectRecord(effectId: pack.id, version: pack.version, params: controlValues, confidenceScore: nil)
                    BeautyTelemetryService.shared.recordEffect(effect)
                }
            }
            .padding()
        }
    }
}


