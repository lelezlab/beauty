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
    @State private var preview: UIImage?
    @State private var realism: Int = 3
    @State private var satisfaction: Int = 3
    @State private var selectedRegions: Set<String> = []

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
                // 预览渲染
                if let preview = preview {
                    Image(uiImage: preview).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)).frame(height: 220).overlay(Text("预览渲染中/占位"))
                }
                Button("记录此次效果使用") {
                    let effect = BTEffectRecord(effectId: pack.id, version: pack.version, params: controlValues, confidenceScore: nil)
                    BeautyTelemetryService.shared.recordEffect(effect)
                }
                // 主观评分与区域
                VStack(alignment: .leading) {
                    Text("主观评分（1–5）")
                    HStack {
                        Stepper("真实感：\(realism)", value: $realism, in: 1...5)
                        Stepper("满意度：\(satisfaction)", value: $satisfaction, in: 1...5)
                    }
                    Text("想改善区域")
                    HStack {
                        ForEach(["nose","chin","zygoma","lips","jawline"], id: \.self) { r in
                            let on = selectedRegions.contains(r)
                            Button(r) { if on { selectedRegions.remove(r) } else { selectedRegions.insert(r) } }
                                .buttonStyle(.borderedProminent)
                                .tint(on ? .blue : .gray)
                        }
                    }
                    Button("提交评分与区域") {
                        let rating = BTRatingRecord(realism: realism, satisfaction: satisfaction, regions: Array(selectedRegions))
                        BeautyTelemetryService.shared.recordRating(rating)
                    }
                }
            }
            .padding()
        }
        .task { await recomputePreview() }
    }
}

extension EffectDetailView {
    func recomputePreview() async {
        let img = CaptureStore.shared.frontImage ?? {
            let size = CGSize(width: 640, height: 800)
            UIGraphicsBeginImageContextWithOptions(size, true, 0)
            UIColor.white.setFill(); UIRectFill(CGRect(origin: .zero, size: size))
            let i = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
            UIGraphicsEndImageContext(); return i
        }()
        let lmk = CaptureStore.shared.frontLandmarks
        let rendered = EffectComposer.render(image: img, pack: pack, controls: controlValues, landmarks: lmk)
        await MainActor.run { self.preview = rendered }
    }
}


