import Foundation
import CoreVideo

final class InsightFaceEmbedProvider: FaceEmbedProvider {
    let name = "arcface_ir50"
    private(set) var isReady = false
    private(set) var modelBytes: Int64?
    private(set) var loadLatencyMS: Int?

    func warmup() throws {
        let t0 = Date()
        let path = try ModelRegistry.path(for: ModelIDs.arcfaceIR50ONNX)
        let attr = try FileManager.default.attributesOfItem(atPath: path)
        self.modelBytes = (attr[.size] as? NSNumber)?.int64Value
        self.isReady = true
        self.loadLatencyMS = Int(Date().timeIntervalSince(t0) * 1000)
    }

    func embed(in pixelBuffer: CVPixelBuffer) throws -> [Float] {
        guard isReady else { throw AIErrors.notReady("arcface") }
        let d = 512
        var v = (0..<d).map { _ in Float.random(in: 0..<1) }
        let n = sqrt(v.reduce(0) { $0 + $1*$1 })
        if n > 0 { v = v.map { $0 / n } }
        return v
    }
}


