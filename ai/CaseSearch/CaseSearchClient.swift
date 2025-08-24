import Foundation

public struct CaseHit: Codable {
    public let caseID: String
    public let distance: Float
    public let previewURL: String?
}

public final class CaseSearchClient {
    private let baseURL: URL
    private let apiKey: String
    public init(baseURL: URL, apiKey: String) {
        self.baseURL = baseURL; self.apiKey = apiKey
    }

    public func search(embedding: [Float], topK: Int = 5) async throws -> [CaseHit] {
        var req = URLRequest(url: baseURL.appendingPathComponent("/rest/v1/rpc/case_search"))
        req.httpMethod = "POST"
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["vec": embedding, "k": topK])
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode([CaseHit].self, from: data)
    }
}


