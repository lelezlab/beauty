import Foundation

protocol TelemetryUploader {
    func upload(eventsFile: URL) async throws
}

final class URLTelemetryUploader: TelemetryUploader {
    let endpoint: URL
    init(endpoint: URL) { self.endpoint = endpoint }

    func upload(eventsFile: URL) async throws {
        let data = try Data(contentsOf: eventsFile)
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/jsonl", forHTTPHeaderField: "Content-Type")
        req.httpBody = data
        _ = try await URLSession.shared.data(for: req)
    }
}


