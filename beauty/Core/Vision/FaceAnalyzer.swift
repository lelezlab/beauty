import Foundation
import Vision
import UIKit

struct FacialLandmarksResult: Codable {
	let boundingBox: CGRect
	let roll: Float
	let yaw: Float
	let pitch: Float
	let points: [String: [CGPoint]]
}

final class FaceAnalyzer {
	func detectLandmarks(in image: UIImage) async throws -> FacialLandmarksResult? {
		guard let cg = image.cgImage else { return nil }
		let request = VNDetectFaceLandmarksRequest()
		let handler = VNImageRequestHandler(cgImage: cg, orientation: .up, options: [:])
		try handler.perform([request])
		guard let face = request.results?.first as? VNFaceObservation else { return nil }
		var dict: [String: [CGPoint]] = [:]
		if let all = face.landmarks {
			let mirror: [(String, VNFaceLandmarkRegion2D?)] = [
				("faceContour", all.faceContour),
				("leftEye", all.leftEye),
				("rightEye", all.rightEye),
				("nose", all.nose),
				("noseCrest", all.noseCrest),
				("medianLine", all.medianLine),
				("outerLips", all.outerLips),
				("innerLips", all.innerLips),
				("leftEyebrow", all.leftEyebrow),
				("rightEyebrow", all.rightEyebrow)
			]
			for (name, region) in mirror {
				if let region = region {
					let points = (0..<region.pointCount).map { idx in
						let p = region.normalizedPoints[idx]
						return CGPoint(x: CGFloat(p.x), y: CGFloat(1 - p.y))
					}
					dict[name] = points
				}
			}
		}
		return FacialLandmarksResult(
			boundingBox: face.boundingBox,
			roll: face.roll?.floatValue ?? 0,
			yaw: face.yaw?.floatValue ?? 0,
			pitch: face.pitch?.floatValue ?? 0,
			points: dict
		)
	}
}


