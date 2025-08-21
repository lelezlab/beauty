import Foundation

enum RemoteConfigService {
    /// Replace with your hosted JSON when ready
    static let defaultURL = URL(string: "https://example.com/beauty/home_data.json")!

    static func fetchHomeConfig(from url: URL = defaultURL) async -> HomeConfig? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            let cfg = try JSONDecoder().decode(HomeConfig.self, from: data)
            cache(data: data)
            return cfg
        } catch {
            if let data = readCache() {
                return try? JSONDecoder().decode(HomeConfig.self, from: data)
            }
            return nil
        }
    }

    private static func cacheURL() -> URL? {
        try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("home_data_cache.json")
    }

    private static func cache(data: Data) {
        guard let url = cacheURL() else { return }
        try? data.write(to: url)
    }

    private static func readCache() -> Data? {
        guard let url = cacheURL() else { return nil }
        return try? Data(contentsOf: url)
    }
}


