import Foundation
import CoreVideo
import CoreGraphics

final class MediaPipeFaceLandmarksProvider: FaceLandmarksProvider {
    let name = "mediapipe_face_landmarker"
    private(set) var isReady = false
    private(set) var modelBytes: Int64?
    private(set) var loadLatencyMS: Int?

    private var runtime: Any?
    private var initialized = false

    func warmup() throws {
        let t0 = Date()
        let path = try ModelRegistry.path(for: ModelIDs.mediapipeTask)
        let attr = try FileManager.default.attributesOfItem(atPath: path)
        self.modelBytes = (attr[.size] as? NSNumber)?.int64Value
        self.runtime = "placeholder"
        self.initialized = true
        self.loadLatencyMS = Int(Date().timeIntervalSince(t0) * 1000)
        self.isReady = true
    }

    func detect(in pixelBuffer: CVPixelBuffer) throws -> [CGPoint] {
        guard isReady, initialized else { throw AIErrors.notReady("mediapipe") }
        let n = 128
        return (0..<n).map { i in
            let t = CGFloat(Double(i) / Double(n) * 2 * Double.pi)
            return CGPoint(x: 0.5 + 0.25 * cos(t), y: 0.5 + 0.25 * sin(t))
        }
    }
}


