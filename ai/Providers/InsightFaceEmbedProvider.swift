import Foundation
import CoreVideo

final class InsightFaceEmbedProvider: FaceEmbedProvider {
    let name = "arcface_ir50"
    private(set) var isReady = false
    private(set) var modelBytes: Int64?
    private(set) var loadLatencyMS: Int?

    func warmup() throws {
        let t0 = Date()
        let path = try ModelRegistry.path(for: "arcface_ir50")
        let attr = try FileManager.default.attributesOfItem(atPath: path)
        self.modelBytes = (attr[.size] as? NSNumber)?.int64Value
        self.isReady = true
        self.loadLatencyMS = Int(Date().timeIntervalSince(t0) * 1000)
    }

    func embed(in pixelBuffer: CVPixelBuffer) throws -> [Float] {
        precondition(isReady)
        return Array(repeating: 0, count: 512)
    }
}


