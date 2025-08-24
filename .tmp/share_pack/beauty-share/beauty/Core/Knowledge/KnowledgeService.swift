import Foundation

enum KnowledgeService {
    static let defaultURL = URL(string: "https://example.com/beauty/knowledge_data.json")!

    static func fetch(from url: URL = defaultURL) async -> [KnowledgeArticle]? {
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return readCache()
            }
            try cache(data)
            let items = try JSONDecoder().decode([KnowledgeArticle].self, from: data)
            return items
        } catch {
            return readCache()
        }
    }

    private static func cacheURL() -> URL? {
        try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("knowledge_data_cache.json")
    }

    private static func cache(_ data: Data) throws {
        guard let url = cacheURL() else { return }
        try data.write(to: url)
    }

    static func readCache() -> [KnowledgeArticle]? {
        guard let url = cacheURL(), let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([KnowledgeArticle].self, from: data)
    }
}

enum KnowledgeFavorites {
    private static let key = "kb_favorites"
    static var keys: Set<String> {
        get {
            let arr = UserDefaults.standard.array(forKey: key) as? [String] ?? []
            return Set(arr)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: key)
        }
    }
    static func isFavorite(_ k: String) -> Bool { keys.contains(k) }
    static func toggle(_ k: String) {
        var s = keys
        if s.contains(k) { s.remove(k) } else { s.insert(k) }
        keys = s
    }
}


