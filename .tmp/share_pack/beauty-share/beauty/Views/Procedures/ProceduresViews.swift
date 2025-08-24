import SwiftUI

struct ProcedureListView: View {
    let category: String // e.g., "nose"
    private var items: [Procedure] { ProcedureStore.byCategory(category).sorted { $0.effectStability > $1.effectStability } }
    @State private var favKeys: Set<String> = KnowledgeFavorites.keys

    var body: some View {
        List {
            if !favKeys.isEmpty {
                Section("收藏夹") {
                    ForEach(items.filter { favKeys.contains($0.id) }) { p in
                        NavigationLink(destination: ProcedureDetailView(p: p)) { row(p) }
                    }
                }
            }
            Section("全部") {
                ForEach(items) { p in
                    NavigationLink(destination: ProcedureDetailView(p: p)) { row(p) }
                }
            }
        }
        .navigationTitle("术式选项")
    }

    private func row(_ p: Procedure) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(p.name).bold()
                if favKeys.contains(p.id) { Image(systemName: "star.fill").foregroundStyle(.yellow) }
            }
            Text(p.summary).font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Label("稳定度\(p.effectStability)", systemImage: "checkmark.seal")
                Label("创伤度\(p.invasiveness)", systemImage: "bandage")
                Text("$\(p.budgetUSD.first ?? 0)-\(p.budgetUSD.last ?? 0)").monospaced().font(.caption)
            }.font(.caption2)
        }
    }
}

struct ProcedureDetailView: View {
    let p: Procedure
    @State private var fav: Bool = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(p.name).font(.title3).bold()
                HStack {
                    Text(p.summary).foregroundStyle(.secondary)
                    Spacer()
                    Button(fav ? "已收藏" : "收藏") {
                        if KnowledgeFavorites.isFavorite(p.id) { KnowledgeFavorites.toggle(p.id) } else { KnowledgeFavorites.toggle(p.id) }
                        fav = KnowledgeFavorites.isFavorite(p.id)
                        BeautyTelemetryService.shared.recordKnowledge(key: p.id, action: fav ? "procedure_favorite_add" : "procedure_favorite_remove")
                    }.buttonStyle(.borderedProminent)
                }
                info("预算(USD)", value: "$\(p.budgetUSD.first ?? 0) - \(p.budgetUSD.last ?? 0)")
                info("恢复期", value: "~\(p.recoveryDays) 天")
                info("证据等级", value: p.evidenceLevel)
                section("原理", items: p.principles)
                section("风险", items: p.risks)
                if let c = p.contraindications, !c.isEmpty { section("禁忌证", items: c) }
                if let a = p.aftercare, !a.isEmpty { section("术后护理", items: a) }
                if let q = p.questionChecklist, !q.isEmpty { section("面诊问题清单", items: q) }
                if let bn = p.budgetNotes, !bn.isEmpty { section("预算提示", items: bn) }
                NavigationLink("选中此术式并查看真实模拟") {
                    ProcedureSimulationPreviewView(procedure: p)
                        .onAppear {
                            CaptureStore.shared.selectedProcedure = p
                            BeautyTelemetryService.shared.recordProcedure(p)
                        }
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("术式详情")
        .onAppear { fav = KnowledgeFavorites.isFavorite(p.id) }
    }

    private func info(_ title: String, value: String) -> some View {
        HStack { Text(title).bold(); Spacer(); Text(value).monospaced() }
    }
    private func section(_ title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).bold()
            ForEach(items, id: \.self) { Text("• \($0)") }
        }
    }
}

struct EffectFromProcedureView: View {
    let category: String
    @State private var autoApplied: Bool = false
    var body: some View {
        // 简化：跳到效果中心，按类别过滤候选包
        EffectsGalleryView(categoryFilter: category)
            .navigationTitle("术后模拟")
    }
}

struct ProcedureSimulationPreviewView: View {
    let procedure: Procedure
    @State private var applied: Bool = false
    @State private var controls: [String: Double] = [:]
    var body: some View {
        VStack(spacing: 12) {
            // 术式参数（按安全边界裁剪）
            sliders
            // 跳转到效果中心（使用当前参数作为建议）
            NavigationLink("查看 3D 预览与效果中心") {
                EffectsGalleryView(categoryFilter: procedure.category, prefilledControls: controls)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .navigationTitle("术后模拟：\(procedure.name)")
        .onAppear {
            if !applied {
                BeautyTelemetryService.shared.recordKnowledge(key: procedure.id, action: "open_procedure_simulation")
                // 基于术式映射和安全边界给出初值
                controls = SurgeryPlanner.makeParams(for: SurgeryMapping(id: procedure.id, name: procedure.name, params: [:], rules: nil, anatomy: nil), base: [:], metrics: nil)
                applied = true
            }
        }
    }

    @ViewBuilder private var sliders: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("参数").font(.headline)
            let keys: [String] = controls.keys.sorted()
            ForEach(keys, id: \.self) { key in
                let val: Double = controls[key] ?? 0
                let safe = SurgeryPlanner.safety(for: key, value: val)
                VStack(alignment: .leading) {
                    let color: Color = (safe.label == "ok") ? .green : (safe.label.contains("soft") ? .orange : .red)
                    HStack { Text(key); Spacer(); Text(String(format: "%.2f", val)).monospaced().foregroundStyle(color) }
                    let minV: Double = AestheticsSafetyConfig.recommended[key]?.min ?? -1
                    let maxV: Double = AestheticsSafetyConfig.recommended[key]?.max ?? 1
                    Slider(value: Binding<Double>(
                        get: { controls[key] ?? 0 },
                        set: { newVal in controls[key] = newVal }
                    ), in: minV...maxV)
                }
            }
        }
    }
}

enum ProcedureSimulationRouter {
    // 将建议 key 映射到对应的术式类别
    static func destination(forKey key: String) -> AnyView? {
        let category: String? = {
            if key.lowercased().contains("鼻") || key.lowercased().contains("naso") { return "nose" }
            if key.lowercased().contains("chin") || key.contains("下巴") { return "chin" }
            if key.lowercased().contains("jaw") || key.contains("下颌") { return "jawline" }
            if key.lowercased().contains("lip") || key.contains("唇") { return "lips" }
            return nil
        }()
        guard let cat = category else { return nil }
        // 选择该类别中稳定度最高的一个术式用于直达模拟（简化）
        let candidates = ProcedureStore.byCategory(cat).sorted { $0.effectStability > $1.effectStability }
        if let first = candidates.first {
            return AnyView(ProcedureSimulationPreviewView(procedure: first))
        }
        return AnyView(EffectsGalleryView(categoryFilter: cat))
    }
}


