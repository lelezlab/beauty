import Foundation
import CoreVideo
import CoreGraphics

final class MediaPipeFaceLandmarksProvider: FaceLandmarksProvider {
    let name = "mediapipe_face_landmarker"
    private(set) var isReady = false
    private(set) var modelBytes: Int64?
    private(set) var loadLatencyMS: Int?

    private var runtime: InferenceBackend?
    private var initialized = false

    func warmup() throws {
        let t0 = Date()
        let path = try ModelRegistry.path(for: ModelIDs.mediapipeTask)
        let attr = try FileManager.default.attributesOfItem(atPath: path)
        self.modelBytes = (attr[.size] as? NSNumber)?.int64Value
        let be = InferenceBackend(type: .none)
        try? be.load(modelPath: path)
        self.runtime = be
        self.initialized = true
        self.loadLatencyMS = Int(Date().timeIntervalSince(t0) * 1000)
        self.isReady = true
    }

    func detect(in pixelBuffer: CVPixelBuffer) throws -> [CGPoint] {
        guard isReady, initialized else { throw AIErrors.notReady("mediapipe") }
        let t0 = Date()
        var points: [CGPoint] = []
        autoreleasepool {
            let ci = CIImage(cvPixelBuffer: pixelBuffer)
            let ctx = CIContext(); if let cg = ctx.createCGImage(ci, from: ci.extent) {
                let ui = UIImage(cgImage: cg)
                points = VisionLandmarksHelper.detectNormalizedPoints(from: ui)
            }
        }
        LatencyTracker.addSample(Date().timeIntervalSince(t0)*1000.0, key: "landmarks_ms")
        return points
    }
}


