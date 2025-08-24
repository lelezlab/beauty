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

    struct Named {
        let leftEye: [CGPoint]?
        let rightEye: [CGPoint]?
        let leftBrow: [CGPoint]?
        let rightBrow: [CGPoint]?
        let nose: [CGPoint]?
        let noseCrest: [CGPoint]?
        let outerLips: [CGPoint]?
        let faceContour: [CGPoint]?
        let medianLine: [CGPoint]?
    }

    static func detectNamed(from image: UIImage) -> Named? {
        guard let cg = image.cgImage else { return nil }
        let req = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cg, orientation: cgOrientation(of: image), options: [:])
        do { try handler.perform([req]) } catch { return nil }
        guard let obs = req.results?.first as? VNFaceObservation, let lm = obs.landmarks else { return nil }
        func conv(_ region: VNFaceLandmarkRegion2D?) -> [CGPoint]? {
            guard let r = region else { return nil }
            return r.normalizedPoints.map { p in
                let x = obs.boundingBox.origin.x + p.x * obs.boundingBox.size.width
                let y = obs.boundingBox.origin.y + p.y * obs.boundingBox.size.height
                return CGPoint(x: x, y: y)
            }
        }
        return Named(leftEye: conv(lm.leftEye), rightEye: conv(lm.rightEye), leftBrow: conv(lm.leftEyebrow), rightBrow: conv(lm.rightEyebrow), nose: conv(lm.nose), noseCrest: conv(lm.noseCrest), outerLips: conv(lm.outerLips), faceContour: conv(lm.faceContour), medianLine: conv(lm.medianLine))
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


