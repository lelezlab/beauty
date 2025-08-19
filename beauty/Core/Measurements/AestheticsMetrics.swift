import Foundation
import CoreGraphics

struct AestheticsMetrics: Codable {
	let threeFacialZonesRatio: CGFloat
	let fiveEyesRatio: CGFloat
	let nasolabialAngleDegrees: CGFloat
	let chinProjectionRatio: CGFloat
	let faceWidthToHeight: CGFloat
}

enum MetricsCalculator {
	static func compute(from landmarks: FacialLandmarksResult, imageSize: CGSize) -> AestheticsMetrics {
		func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
		let points = landmarks.points

		let faceContour = points["faceContour"] ?? []
		let leftEye = points["leftEye"] ?? []
		let rightEye = points["rightEye"] ?? []
		let nose = points["nose"] ?? []
		let outerLips = points["outerLips"] ?? []

		func meanY(_ pts: [CGPoint]) -> CGFloat { guard !pts.isEmpty else { return 0 }; return pts.map { $0.y }.reduce(0, +) / CGFloat(pts.count) }
		let topY = faceContour.min(by: { $0.y < $1.y })?.y ?? 0
		let bottomY = faceContour.max(by: { $0.y < $1.y })?.y ?? 1
		let hairlineToBrow: CGFloat = max(meanY(leftEye + rightEye) - topY, 0.0001)
		let browToNoseBase: CGFloat = max((nose.max(by: { $0.y < $1.y })?.y ?? 0) - meanY(leftEye + rightEye), 0.0001)
		let noseBaseToChin: CGFloat = max(bottomY - (nose.max(by: { $0.y < $1.y })?.y ?? bottomY), 0.0001)
		let threeZones = hairlineToBrow / browToNoseBase + browToNoseBase / noseBaseToChin + noseBaseToChin / hairlineToBrow

		let eyeDistance = distance(leftEye.center, rightEye.center)
		let faceWidth = (faceContour.max(by: { $0.x < $1.x })?.x ?? 1) - (faceContour.min(by: { $0.x < $1.x })?.x ?? 0)
		let fiveEyes = faceWidth / max(eyeDistance, 0.0001)

		let subnasale = nose.max(by: { $0.y < $1.y }) ?? .zero
		let labraleSuperius = outerLips.min(by: { $0.y < $1.y }) ?? .zero
		let columellaPoint = nose.min(by: { $0.y < $1.y }) ?? .zero
		let v1 = CGVector(dx: labraleSuperius.x - subnasale.x, dy: labraleSuperius.y - subnasale.y)
		let v2 = CGVector(dx: columellaPoint.x - subnasale.x, dy: columellaPoint.y - subnasale.y)
		let angle = acos(max(-1, min(1, (v1.dx*v2.dx + v1.dy*v2.dy) / (hypot(v1.dx, v1.dy) * hypot(v2.dx, v2.dy) + 1e-6)))) * 180 / .pi

		let pogonion = faceContour.max(by: { $0.x < $1.x }) ?? .zero
		let lipsCenter = outerLips.center
		let chinProjection = distance(pogonion, lipsCenter) / max(faceWidth, 0.0001)

		let faceHeight = bottomY - topY
		let faceWH = faceWidth / max(faceHeight, 0.0001)

		return AestheticsMetrics(
			threeFacialZonesRatio: threeZones,
			fiveEyesRatio: fiveEyes,
			nasolabialAngleDegrees: angle,
			chinProjectionRatio: chinProjection,
			faceWidthToHeight: faceWH
		)
	}
}

private extension Array where Element == CGPoint {
	var center: CGPoint {
		guard !isEmpty else { return .zero }
		let x = map { $0.x }.reduce(0, +) / CGFloat(count)
		let y = map { $0.y }.reduce(0, +) / CGFloat(count)
		return CGPoint(x: x, y: y)
	}
}


