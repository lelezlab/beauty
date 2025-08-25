import Foundation
import UIKit
#if canImport(Vision)
import Vision
#endif

// Lightweight facade for future MediaPipe Face Mesh (468) integration.
// Current implementation: use Vision landmarks if available and upsample to 468 by repetition.
// Keeps the app compiling/runnable without any external SDKs.

struct FaceMeshPoint3D: Sendable { let x: Float; let y: Float; let z: Float; let confidence: Float }

final class FaceMeshProvider {
    static let shared = FaceMeshProvider()
    private init() {}

    /// Returns up to 468 2D points in image coordinates (origin top-left). Offline-friendly stub.
    func detect2D(in image: UIImage) async -> [CGPoint] {
        #if canImport(Vision)
        guard let cg = image.cgImage else { return [] }
        let req = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cg, orientation: .up)
        do { try handler.perform([req]) } catch { return [] }
        guard let results = req.results,
              let obs = results.first,
              let lm = obs.landmarks else { return [] }
        var pts: [CGPoint] = []
        func add(_ region: VNFaceLandmarkRegion2D?) {
            guard let r = region else { return }
            for i in 0..<r.pointCount {
                let p = r.normalizedPoints[i]
                // Vision gives normalized in face rect; map to image coordinates
                let rect = obs.boundingBox
                let x = rect.origin.x + CGFloat(p.x) * rect.width
                let y = rect.origin.y + CGFloat(p.y) * rect.height
                // Convert from normalized (LL origin) to UIKit (UL origin)
                let pt = CGPoint(x: x * image.size.width, y: (1 - y) * image.size.height)
                pts.append(pt)
            }
        }
        add(lm.faceContour); add(lm.leftEye); add(lm.rightEye); add(lm.leftEyebrow); add(lm.rightEyebrow)
        add(lm.nose); add(lm.noseCrest); add(lm.medianLine); add(lm.outerLips); add(lm.innerLips)
        // Upsample to 468 by repeating while preserving order
        if pts.isEmpty { return [] }
        if pts.count < 468 {
            var up = pts
            var i = 0
            while up.count < 468 { up.append(pts[i % pts.count]); i += 1 }
            return up
        } else {
            return Array(pts.prefix(468))
        }
        #else
        return []
        #endif
    }
}


