import Foundation

@MainActor
public final class AIOrchestrator {
    public static let shared = AIOrchestrator()
    private init() {}
    public func warmupAll() async { /* no-op placeholder to satisfy build; real impl in ai/ */ }
}


