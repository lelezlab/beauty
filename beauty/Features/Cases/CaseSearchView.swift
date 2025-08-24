import SwiftUI

struct CaseSearchItem: Identifiable, Decodable {
    let id: String
    let procedure: String
    let monthsAfter: Int
    let similarity: Double
    let thumbnail: String?
}

struct CaseSearchView: View {
    @State private var items: [CaseSearchItem] = []
    var body: some View {
        List(items) { it in
            HStack(spacing: 12) {
                Rectangle().fill(.gray.opacity(0.2)).frame(width: 64, height: 64).overlay(Text("IMG").font(.caption))
                VStack(alignment: .leading, spacing: 4) {
                    Text(it.procedure).font(.headline)
                    Text("术后 \(it.monthsAfter) 个月  •  相似度 \(String(format: "%.2f", it.similarity))").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("相似案例")
        .onAppear { load() }
    }
    private func load() {
        // Static JSON fallback for UI demo
        if let url = Bundle.main.url(forResource: "static_cases", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let arr = try? JSONDecoder().decode([CaseSearchItem].self, from: data) {
            items = arr
        } else {
            items = [
                .init(id: "1", procedure: "隆鼻 + 鼻尖上旋", monthsAfter: 6, similarity: 0.82, thumbnail: nil),
                .init(id: "2", procedure: "颏成形（填充）", monthsAfter: 3, similarity: 0.79, thumbnail: nil)
            ]
        }
    }
}


