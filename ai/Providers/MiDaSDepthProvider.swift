import Foundation
import CoreVideo

final class MiDaSDepthProvider: DepthProvider {
    let name = "midas_depth"
    private(set) var isReady = false
    private(set) var modelBytes: Int64?
    private(set) var loadLatencyMS: Int?

    func warmup() throws {
        let t0 = Date()
        let path = try ModelRegistry.path(for: "midas_s")
        let attr = try FileManager.default.attributesOfItem(atPath: path)
        self.modelBytes = (attr[.size] as? NSNumber)?.int64Value
        self.isReady = true
        self.loadLatencyMS = Int(Date().timeIntervalSince(t0) * 1000)
    }

    func depth(in pixelBuffer: CVPixelBuffer) throws -> (depth: [Float], width: Int, height: Int) {
        precondition(isReady)
        return ([], 0, 0)
    }
}


