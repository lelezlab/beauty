import SwiftUI

struct SafetyBanner: View {
    @State private var items: [KBCard] = []
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !items.isEmpty {
                HStack {
                    Text("安全快讯").bold()
                    Spacer()
                    if let d = items.first?.date, isNew(d) { Text("NEW").font(.caption2).padding(4).background(Color.red, in: Capsule()).foregroundStyle(.white) }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items) { c in
                            Link(destination: URL(string: c.source_url)!) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(c.title).font(.subheadline).lineLimit(1)
                                    HStack { Text(sourceOf(c)).font(.caption2).foregroundStyle(.secondary); Text(relative(c.date)).font(.caption2).foregroundStyle(.secondary) }
                                }
                                .padding(8)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        guard let base = SupabaseConfig.url ?? URL(string: SupabaseEnv.url) else { return }
        let src = "openFDArecall,BAAPS,ASPS"
        var req = URLRequest(url: base.appendingPathComponent("/rest/v1/kb_docs?source=in.(\(src))&order=published_at.desc&limit=5"))
        if !SupabaseEnv.anonKey.isEmpty { req.setValue(SupabaseEnv.anonKey, forHTTPHeaderField: "apikey") }
        if !SupabaseEnv.anonKey.isEmpty { req.setValue("Bearer \(SupabaseEnv.anonKey)", forHTTPHeaderField: "Authorization") }
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return }
            if let arr = try? JSONDecoder().decode([KBCard].self, from: data) { items = arr }
        } catch { }
    }

    private func sourceOf(_ c: KBCard) -> String { URL(string: c.source_url)?.host ?? "source" }
    private func relative(_ d: String?) -> String { d ?? "" }
    private func isNew(_ d: String) -> Bool { true }
}


