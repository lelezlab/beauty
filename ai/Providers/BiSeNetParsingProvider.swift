import Foundation
import CoreVideo

final class BiSeNetParsingProvider: FaceParsingProvider {
    let name = "bisenet_face_parsing"
    private(set) var isReady = false
    private(set) var modelBytes: Int64?
    private(set) var loadLatencyMS: Int?

    func warmup() throws {
        let t0 = Date()
        let path = try ModelRegistry.path(for: "face_parsing_bisenet")
        let attr = try FileManager.default.attributesOfItem(atPath: path)
        self.modelBytes = (attr[.size] as? NSNumber)?.int64Value
        self.isReady = true
        self.loadLatencyMS = Int(Date().timeIntervalSince(t0) * 1000)
    }

    func parse(in pixelBuffer: CVPixelBuffer) throws -> (labels: [UInt8], width: Int, height: Int) {
        precondition(isReady)
        return ([], 0, 0)
    }
}


