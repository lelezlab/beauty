import SwiftUI

struct KBCard: Identifiable, Codable { let id: String; let title: String; let abstract: String?; let date: String?; let source_url: String }

struct NewsFeedView: View {
    @State private var cards: [KBCard] = []
    var body: some View {
        List(cards) { c in
            VStack(alignment: .leading, spacing: 6) {
                Text(c.title).bold()
                if let a = c.abstract { Text(a).font(.caption).foregroundStyle(.secondary) }
                HStack {
                    if let d = c.date { Text(d).font(.caption2).foregroundStyle(.secondary) }
                    Spacer()
                    Link("来源", destination: URL(string: c.source_url)!)
                }
            }
            .padding(.vertical, 6)
        }
        .navigationTitle("今日更新")
        .task { await load() }
    }

    private func load() async {
        guard let base = SupabaseConfig.url ?? URL(string: SupabaseEnv.url) else { return }
        var req = URLRequest(url: base.appendingPathComponent("/rest/v1/kb_docs?select=id,title,abstract,date,source_url&order=date.desc&limit=50"))
        if !SupabaseEnv.anonKey.isEmpty { req.setValue(SupabaseEnv.anonKey, forHTTPHeaderField: "apikey") }
        if !SupabaseEnv.anonKey.isEmpty { req.setValue("Bearer \(SupabaseEnv.anonKey)", forHTTPHeaderField: "Authorization") }
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return }
            if let arr = try? JSONDecoder().decode([KBCard].self, from: data) { cards = arr }
        } catch { }
    }
}


