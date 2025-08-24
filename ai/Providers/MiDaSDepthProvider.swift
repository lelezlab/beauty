import Foundation
import CoreVideo

final class MiDaSDepthProvider: DepthProvider {
    let name = "midas_depth"
    private(set) var isReady = false
    private(set) var modelBytes: Int64?
    private(set) var loadLatencyMS: Int?

    func warmup() throws {
        let t0 = Date()
        let path = try ModelRegistry.path(for: ModelIDs.midasSmallONNX)
        let attr = try FileManager.default.attributesOfItem(atPath: path)
        self.modelBytes = (attr[.size] as? NSNumber)?.int64Value
        self.isReady = true
        self.loadLatencyMS = Int(Date().timeIntervalSince(t0) * 1000)
    }

    func depth(in pixelBuffer: CVPixelBuffer) throws -> (depth: [Float], width: Int, height: Int) {
        guard isReady else { throw AIErrors.notReady("midas") }
        let w = CVPixelBufferGetWidth(pixelBuffer)
        let h = CVPixelBufferGetHeight(pixelBuffer)
        return (Array(repeating: 0.5, count: w*h), w, h)
    }
}


