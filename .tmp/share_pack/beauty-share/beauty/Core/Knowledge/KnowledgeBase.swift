import Foundation

struct KnowledgeArticle: Codable, Identifiable {
    var id: String { key }
    let key: String
    let title: String
    let summary: String
    let sections: [Section]

    struct Section: Codable { let heading: String; let body: String }
}

enum KnowledgeBase {
    static func all() -> [KnowledgeArticle] {
        guard let url = Bundle.main.url(forResource: "knowledge_data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([KnowledgeArticle].self, from: data) else { return [] }
        return items
    }

    static func article(for key: String) -> KnowledgeArticle? {
        return all().first { $0.key == key }
    }
}


