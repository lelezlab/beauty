import Foundation
import Vision
import UIKit

enum FallbackFaceCapture {
    static func detectLandmarks(in image: UIImage) async -> [String: [CGPoint]]? {
        guard let cg = image.cgImage else { return nil }
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        try? handler.perform([request])
        guard let obs = request.results?.first as? VNFaceObservation else { return nil }
        var points: [String: [CGPoint]] = [:]
        if let all = obs.landmarks?.allPoints?.normalizedPoints { points["all"] = all.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) } }
        return points
    }
}


