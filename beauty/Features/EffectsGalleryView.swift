import SwiftUI
import UIKit

struct EffectsGalleryView: View {
    var categoryFilter: String? = nil
    @StateObject private var center = EffectCenter.shared
    @State private var manifestURL: String = (Bundle.main.object(forInfoDictionaryKey: "AppManifestURL") as? String) ?? ""

    var body: some View {
        List {
            if center.activeEffects.isEmpty {
                Section {
                    Text("暂无效果包。可先使用内置本地包，或输入 Manifest URL 点击拉取。").font(.caption).foregroundStyle(.secondary)
                }
            }
            if categoryFilter == nil {
                Section("远程清单") {
                    HStack { TextField("Manifest URL", text: $manifestURL).textInputAutocapitalization(.never); Button("拉取") { Task { try? await center.fetchManifest(from: URL(string: manifestURL)!); await center.syncEffects(deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "dev", appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0", regionCode: Locale.current.region?.identifier ?? "US") } } }
                }
            }

            Section("效果列表") {
                ForEach(center.activeEffects.filter { categoryFilter == nil ? true : ($0.category == categoryFilter!) }) { pack in
                    NavigationLink(pack.display_name) { EffectDetailView(pack: pack) }
                }
                if center.activeEffects.isEmpty {
                    NavigationLink("打开本地鼻部示例包") {
                        if let p = try? JSONDecoder().decode(EffectPack.self, from: (try? Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "Effects/local/rhinoplasty_2025Q3_01", ofType: "json") ?? ""))) ?? Data()) {
                            EffectDetailView(pack: p)
                        } else { Text("本地示例包丢失") }
                    }
                }
            }
        }
        .navigationTitle("效果中心")
        .onAppear {
            // 离线兜底，先加载本地效果包
            if center.activeEffects.isEmpty { center.loadLocalIfAvailable() }
            // 若配置了默认 URL，自动尝试拉取
            if manifestURL.isEmpty, let urlStr = Bundle.main.object(forInfoDictionaryKey: "AppManifestURL") as? String { manifestURL = urlStr }
        }
    }
}

struct EffectDetailView: View {
    let pack: EffectPack
    @State private var controlValues: [String: Double] = [:]
    @State private var preview: UIImage?
    @State private var previewLeft: UIImage?
    @State private var previewRight: UIImage?
    @State private var multiViewLinked: Bool = false
    @State private var showGoldenMask: Bool = false
    @State private var realism: Int = 3
    @State private var satisfaction: Int = 3
    @State private var selectedRegions: Set<String> = []
    @State private var safetyStates: [String: String] = [:]
    @State private var selectedSurgery: SurgeryMapping? = nil
    @State private var showAnatomy: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(pack.display_name).font(.title3).bold()
                Text("免责声明：仅为视觉模拟，非医疗建议。").font(.footnote).foregroundStyle(.secondary)
                // 风格模板
                Group {
                    Text("风格模板").font(.subheadline).bold()
                    HStack {
                        ForEach(["自然","韩系","日系","欧系"], id: \.self) { name in
                            Button(name) {
                                let tpl = StyleTemplates.template(named: name)
                                var merged = controlValues
                                for (k, v) in tpl {
                                    if pack.controls.contains(where: { $0.key == k }) {
                                        merged[k] = v
                                    }
                                }
                                controlValues = merged
                                BeautyTelemetryService.shared.recordPrefill(.init(source: "StyleTemplate: \(name)", procedureId: CaptureStore.shared.selectedProcedure?.id, weights: nil, params: merged))
                                Task { await recomputePreview() }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                HStack {
                    Button("一键参考黄金法则") {
                        if let lmk = CaptureStore.shared.frontLandmarks {
                            // 使用真实指标评估映射
                            let m = MetricsCalculator.compute(from: lmk, imageSize: CGSize(width: 1, height: 1))
                            let assess = AestheticsAssessor.assess(metrics: m)
                            var merged = controlValues
                            for item in assess.items {
                                for (k, v) in item.suggestion { merged[k] = (merged[k] ?? 0) + v }
                            }
                            controlValues = merged
                            BeautyTelemetryService.shared.recordPrefill(.init(source: "GoldenGuides", procedureId: nil, weights: nil, params: merged))
                            Task { await recomputePreview() }
                        }
                    }
                    Button("一键应用推荐值") {
                        if let lmk = CaptureStore.shared.frontLandmarks {
                            let m = MetricsCalculator.compute(from: lmk, imageSize: CGSize(width: 1, height: 1))
                            let assess = AestheticsAssessor.assess(metrics: m)
                            var merged = controlValues
                            for item in assess.items {
                                for (k, v) in item.suggestion {
                                    let clamped = clampToSafetyIfNeeded(key: k, value: (merged[k] ?? 0) + v)
                                    merged[k] = clamped
                                }
                            }
                            // 若选择了术式，叠加术式权重
                            if let chosen = CaptureStore.shared.selectedProcedure {
                                let weights = ProcedureWeights.weights(forCategory: chosen.category)
                                for (k, val) in merged {
                                    let w = weights[k] ?? 1.0
                                    merged[k] = val * w
                                }
                            }
                            controlValues = merged
                            BeautyTelemetryService.shared.recordPrefill(.init(source: "ApplyRecommended", procedureId: CaptureStore.shared.selectedProcedure?.id, weights: nil, params: merged))
                            Task { await recomputePreview() }
                        }
                    }
                }
                // 术式选择 + 自动映射
                Group {
                    Text("按术式选择").font(.subheadline).bold()
                    let catalog = SurgeryCatalog.load()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(catalog, id: \.id) { m in
                                let on = selectedSurgery?.id == m.id
                                Button(m.name) {
                                    selectedSurgery = m
                                    if let lmk = CaptureStore.shared.frontLandmarks {
                                        let mtx = MetricsCalculator.compute(from: lmk, imageSize: CGSize(width: 1, height: 1))
                                        controlValues = SurgeryPlanner.makeParams(for: m, base: controlValues, metrics: mtx)
                                        Task { await recomputePreview() }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(on ? .blue : .gray)
                            }
                        }
                    }
                    if let s = selectedSurgery, let anat = s.anatomy, !anat.isEmpty {
                        Button("查看对应解剖结构") { showAnatomy = true }
                            .buttonStyle(.bordered)
                            .sheet(isPresented: $showAnatomy) { AnatomyView(targets: anat) }
                    }
                }
                // 若用户已在术式页选择了术式，提供“一键应用术式建议”
                if let chosen = CaptureStore.shared.selectedProcedure {
                    Button("一键应用术式建议：\(chosen.name)") {
                        if let lmk = CaptureStore.shared.frontLandmarks {
                            let m = MetricsCalculator.compute(from: lmk, imageSize: CGSize(width: 1, height: 1))
                            let assess = AestheticsAssessor.assess(metrics: m)
                            var merged = controlValues
                            // 程序化权重：按术式类别增强/抑制不同控件影响
                            let weights = ProcedureWeights.weights(forCategory: chosen.category)
                            for item in assess.items {
                                for (k, v) in item.suggestion {
                                    let w = weights[k] ?? 1.0
                                    merged[k] = (merged[k] ?? 0) + v * w
                                }
                            }
                            controlValues = merged
                            BeautyTelemetryService.shared.recordPrefill(.init(source: "Procedure", procedureId: chosen.id, weights: weights, params: merged))
                            Task { await recomputePreview() }
                        }
                    }
                }
                ForEach(pack.controls) { c in
                    VStack(alignment: .leading) {
                        let val = controlValues[c.key] ?? (c.default ?? 0)
                        let state = safetyColorState(for: c.key, value: val)
                        HStack {
                            Text(c.key)
                            Spacer()
                            Circle().fill(state.color).frame(width: 10, height: 10)
                            Text(String(format: "%.2f", val))
                        }
                        if let r = c.range, r.count == 2 {
                            Slider(value: Binding(get: { controlValues[c.key] ?? (c.default ?? 0) }, set: { newVal in
                                let clamped = clampToSafetyIfNeeded(key: c.key, value: newVal)
                                controlValues[c.key] = clamped
                                safetyStates[c.key] = safetyColorState(for: c.key, value: newVal).label
                            }), in: r[0]...r[1])
                        }
                    }
                }
                Toggle("三视图联动", isOn: $multiViewLinked)
                Toggle("叠加黄金比例面罩", isOn: $showGoldenMask)
                // 预览渲染（单图或三图）
                if multiViewLinked, let f = preview, let l = previewLeft, let r = previewRight {
                    HStack(alignment: .top, spacing: 8) {
                        Image(uiImage: l).resizable().scaledToFit()
                        ZStack(alignment: .topLeading) {
                            Image(uiImage: f).resizable().scaledToFit()
                            if showGoldenMask { GoldenGuidesOverlay(landmarks: CaptureStore.shared.frontLandmarks).padding(4) }
                        }
                        Image(uiImage: r).resizable().scaledToFit()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if let preview = preview {
                    ZStack(alignment: .topLeading) {
                        Image(uiImage: preview).resizable().scaledToFit()
                        if RemoteEffectsFlags.goldenGuidesEnabled && showGoldenMask {
                            GoldenMask2DOverlay(landmarks: CaptureStore.shared.frontLandmarks).padding(4)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)).frame(height: 220).overlay(Text("预览渲染中/占位"))
                }
                // 分屏滑杆对比（仅单图时）
                if !multiViewLinked, let before = CaptureStore.shared.frontImage, let after = preview {
                    BeforeAfterSlider(before: before, after: after)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                if let before = CaptureStore.shared.frontImage, let after = preview {
                    Button("导出前后对比 PDF") {
                        let img = ExportService.compositeBeforeAfter(before: before, after: after, watermark: "beauty demo - not for medical use", layout: .vertical, showAB: true, regionText: RegionManager().displayName) ?? after
                        let mp: BTMetricsPayload? = {
                            if let m = CaptureStore.shared.frontLandmarks.map({ MetricsCalculator.compute(from: $0, imageSize: before.size) }) {
                                let conf = ConfidenceEstimator.score(from: BeautyTelemetryService.shared.lastQC ?? BTCaptureQC(blurScore: 0.2, exposureMean: 0.6, faceCoverage: 0.6, yaw: nil, pitch: nil, roll: nil, focalEq: nil, distanceBucket: 3, aeLocked: nil, awbLocked: nil, alignScore: 0.6))
                                return BTMetricsPayload(threeZones: Double(m.threeFacialZonesRatio), fiveEyes: Double(m.fiveEyesRatio), nasolabialDeg: Double(m.nasolabialAngleDegrees), chinProjection: Double(m.chinProjectionRatio), faceWH: Double(m.faceWidthToHeight), confidence: conf)
                            }
                            return nil
                        }()
                        if let pdf = ExportService.makePDF(from: img, disclaimer: "仅为视觉模拟，非医疗建议。", procedure: CaptureStore.shared.selectedProcedure, metrics: mp, location: RegionManager().displayName, timestamp: Date(), bddScore: BeautyTelemetryService.shared.lastBDDScore, consistency: multiViewLinked ? MultiViewMorpher.consistencyScore(front: CaptureStore.shared.frontLandmarks, left: CaptureStore.shared.leftLandmarks, right: CaptureStore.shared.rightLandmarks) : nil) {
                            share(data: pdf, fileName: "beauty_effect_preview.pdf")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    // 本地“像谁 Top3”
                    NavigationLink("术后像谁（离线）") {
                        CelebMatchView(image: after)
                    }
                }
                // 一致性评分展示
                if multiViewLinked {
                    let s = MultiViewMorpher.consistencyScore(front: CaptureStore.shared.frontLandmarks,
                                                               left: CaptureStore.shared.leftLandmarks,
                                                               right: CaptureStore.shared.rightLandmarks)
                    Text(String(format: "三视图一致性 %.0f%%", s*100)).font(.caption).padding(6).background(Color.blue.opacity(0.2), in: Capsule())
                }
                Button("记录此次效果使用") {
                    let params = controlValues
                    let pid = CaptureStore.shared.selectedProcedure?.id
                    let cons = multiViewLinked ? MultiViewMorpher.consistencyScore(front: CaptureStore.shared.frontLandmarks,
                                                                                    left: CaptureStore.shared.leftLandmarks,
                                                                                    right: CaptureStore.shared.rightLandmarks) : nil
                    let effect = BTEffectRecord(effectId: pack.id, version: pack.version, params: params, confidenceScore: nil, safety: safetyStates, procedureId: pid, consistency: cons)
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
                        let rating = BTRatingRecord(realism: realism, satisfaction: satisfaction, regions: Array(selectedRegions), bddScore: nil)
                        BeautyTelemetryService.shared.recordRating(rating)
                    }
                }
            }
            .padding()
        }
        .task { await recomputePreview() }
        .onAppear {
            // 首次进入，若有选中的术式，则依据评估把建议值填入控件
            guard controlValues.isEmpty else { return }
            if let _ = CaptureStore.shared.selectedProcedure, let lmk = CaptureStore.shared.frontLandmarks {
                let m = MetricsCalculator.compute(from: lmk, imageSize: CGSize(width: 1, height: 1))
                let assess = AestheticsAssessor.assess(metrics: m)
                var merged = controlValues
                for item in assess.items {
                    for (k, v) in item.suggestion { merged[k] = (merged[k] ?? 0) + v }
                }
                controlValues = merged
            }
        }
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
        var leftOut: UIImage? = nil
        var rightOut: UIImage? = nil
        if multiViewLinked, let left = CaptureStore.shared.leftImage, let right = CaptureStore.shared.rightImage {
            let triple = MultiViewMorpher.solve(front: rendered, left: left, right: right, pack: pack, controls: controlValues, frontLandmarks: lmk)
            leftOut = triple.left
            rightOut = triple.right
            await MainActor.run { self.previewLeft = leftOut; self.previewRight = rightOut }
        }
        await MainActor.run { self.preview = rendered }
    }

    private func safetyColorState(for key: String, value: Double) -> (label: String, color: Color) {
        if let w = AestheticsSafetyConfig.recommended[key] {
            if value >= w.min && value <= w.max { return ("green", .green) }
            let span = w.max - w.min
            if value >= w.min - span*0.2 && value <= w.max + span*0.2 { return ("orange", .orange) }
            return ("red", .red)
        }
        return ("unknown", .gray)
    }

    private func clampToSafetyIfNeeded(key: String, value: Double) -> Double {
        guard let w = AestheticsSafetyConfig.recommended[key] else { return value }
        return min(max(value, w.min), w.max)
    }
}

private func share(data: Data, fileName: String) {
    let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    try? data.write(to: tmp)
    DispatchQueue.main.async {
        let av = UIActivityViewController(activityItems: [tmp], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?
            .rootViewController?
            .present(av, animated: true)
    }
}

enum StyleTemplates {
    // 返回控件键→目标值，仅对当前效果包中存在的键生效
    static func template(named name: String) -> [String: Double] {
        switch name {
        case "自然":
            return [
                "tip_rotation": 2,
                "bridge_straighten": 0.15,
                "chin_projection": 0.1,
                "jaw_sharpen": 0.1,
                "lip_volume": 0.05
            ]
        case "韩系":
            return [
                "tip_rotation": 6,
                "bridge_straighten": 0.35,
                "chin_projection": 0.22,
                "jaw_sharpen": 0.18,
                "lip_volume": 0.15
            ]
        case "日系":
            return [
                "tip_rotation": 4,
                "bridge_straighten": 0.18,
                "chin_projection": 0.12,
                "jaw_sharpen": 0.08,
                "lip_volume": 0.1
            ]
        case "欧系":
            return [
                "tip_rotation": 3,
                "bridge_straighten": 0.5,
                "chin_projection": 0.28,
                "jaw_sharpen": 0.25,
                "lip_volume": 0.12
            ]
        default:
            return [:]
        }
    }
}


