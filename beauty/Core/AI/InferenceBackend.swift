import Foundation

/// Minimal inference backend abstraction to prepare for ORT/CoreML drop-in.
enum InferenceBackendType: String { case coreml, onnxrt, none }

final class InferenceBackend {
    let type: InferenceBackendType
    private(set) var isLoaded: Bool = false
    private(set) var modelPath: String?
    init(type: InferenceBackendType) { self.type = type }

    func load(modelPath: String) throws {
        // In this scaffold, we only record the path to surface diagnostics.
        self.modelPath = modelPath
        self.isLoaded = true
    }

    func run(inputs: [String: Any]) throws -> [String: Any] {
        // No-op placeholder; real implementation will dispatch to ORT/CoreML.
        return [:]
    }
}


