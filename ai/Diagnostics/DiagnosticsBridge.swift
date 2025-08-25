import Foundation

public struct AIModuleDiagnostics: Codable {
    public let provider: String
    public let ready: Bool
    public let loadLatencyMS: Int?
    public let modelBytes: Int64?
}

public enum AIDiagnostics {
    public static func snapshot(providers: [AIModelProvider]) -> [AIModuleDiagnostics] {
        providers.map {
            AIModuleDiagnostics(provider: $0.name,
                                ready: $0.isReady,
                                loadLatencyMS: $0.loadLatencyMS,
                                modelBytes: $0.modelBytes)
        }
    }
}


