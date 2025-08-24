import Foundation

public enum AIErrors: Error, LocalizedError {
    case notReady(String)
    case invalidInput(String)
    case runtime(String)
    case timeout(String)

    public var errorDescription: String? {
        switch self {
        case .notReady(let m):   return "AI not ready: \(m)"
        case .invalidInput(let m): return "AI invalid input: \(m)"
        case .runtime(let m):    return "AI runtime error: \(m)"
        case .timeout(let m):    return "AI timeout: \(m)"
        }
    }
}


