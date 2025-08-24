import Foundation
import CoreVideo

final class BiSeNetParsingProvider: FaceParsingProvider {
    let name = "bisenet_face_parsing"
    private(set) var isReady = false
    private(set) var modelBytes: Int64?
    private(set) var loadLatencyMS: Int?

    func warmup() throws {
        let t0 = Date()
        let path = try ModelRegistry.path(for: ModelIDs.bisenetONNX)
        let attr = try FileManager.default.attributesOfItem(atPath: path)
        self.modelBytes = (attr[.size] as? NSNumber)?.int64Value
        self.isReady = true
        self.loadLatencyMS = Int(Date().timeIntervalSince(t0) * 1000)
    }

    func parse(in pixelBuffer: CVPixelBuffer) throws -> (labels: [UInt8], width: Int, height: Int) {
        guard isReady else { throw AIErrors.notReady("bisenet") }
        let w = CVPixelBufferGetWidth(pixelBuffer)
        let h = CVPixelBufferGetHeight(pixelBuffer)
        return (Array(repeating: 0, count: w*h), w, h)
    }
}


