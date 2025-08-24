import Foundation
import CoreML

// Placeholder facade for ONNX Runtime Mobile.
// Keeps API stable even when ORT is not linked; provide simple errors.

enum ORTMobile {
    struct Model {
        let name: String
        // In a real integration, we would keep a session/allocator here.
    }

    enum ORTError: Error { case notLinked, inferenceFailed }

    static func load(modelNamed: String) throws -> Model { throw ORTError.notLinked }
    static func run(_ model: Model, inputs: [String: Any]) throws -> [String: Any] { throw ORTError.notLinked }
}


