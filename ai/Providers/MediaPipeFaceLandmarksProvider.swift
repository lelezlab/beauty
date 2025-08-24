import Foundation
import CoreVideo

final class MediaPipeFaceLandmarksProvider: FaceLandmarksProvider {
    let name = "mediapipe_face_landmarker"
    private(set) var isReady = false
    private(set) var modelBytes: Int64?
    private(set) var loadLatencyMS: Int?

    private var runtime: Any?

    func warmup() throws {
        let t0 = Date()
        let path = try ModelRegistry.path(for: "facemesh_mediapipe_task")
        let attr = try FileManager.default.attributesOfItem(atPath: path)
        self.modelBytes = (attr[.size] as? NSNumber)?.int64Value
        self.runtime = "placeholder"
        self.loadLatencyMS = Int(Date().timeIntervalSince(t0) * 1000)
        self.isReady = true
    }

    func detect(in pixelBuffer: CVPixelBuffer) throws -> [CGPoint] {
        precondition(isReady, "call warmup() first")
        return []
    }
}


