import Foundation
import Vision
import UIKit

enum VisionLandmarksHelper {
    /// Detect 2D landmarks normalized to image coordinates [0,1]. Returns empty on failure.
    static func detectNormalizedPoints(from image: UIImage) -> [CGPoint] {
        guard let cg = image.cgImage else { return [] }
        let req = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cg, orientation: cgOrientation(of: image), options: [:])
        do { try handler.perform([req]) } catch { return [] }
        guard let obs = req.results?.first as? VNFaceObservation, let all = obs.landmarks?.allPoints else { return [] }
        let bbox = obs.boundingBox // in normalized image coords (origin at bottom-left)
        let points = all.normalizedPoints.map { p -> CGPoint in
            // p is in face bbox space (origin bottom-left). Convert to image normalized.
            let x = bbox.origin.x + p.x * bbox.size.width
            let y = bbox.origin.y + p.y * bbox.size.height
            return CGPoint(x: x, y: y)
        }
        return points
    }

    static func cgOrientation(of image: UIImage) -> CGImagePropertyOrientation {
        switch image.imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}


