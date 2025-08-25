import Foundation
import CoreGraphics

struct AestheticsMetrics: Codable {
	let threeFacialZonesRatio: CGFloat
	let fiveEyesRatio: CGFloat
	let nasolabialAngleDegrees: CGFloat
	let chinProjectionRatio: CGFloat
	let faceWidthToHeight: CGFloat
	// 新增细项
	let innerCanthusAngleDeg: CGFloat
	let nasalWidthMM: CGFloat
	let lowerFaceAngleDeg: CGFloat
	let lipCurvatureDeg: CGFloat
	// 补充：若无法可靠计算则为 nil
	let intercanthalDistanceMM: CGFloat?
	let browToEyeDistanceMM: CGFloat?
	let palpebralFissureHeightMM: CGFloat?
	let mandibularAngleDegrees: CGFloat?
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

		// 细项示例：内眦角、鼻翼宽、下颌角、唇弓曲率（占位近似）
		let innerCanthusAngle: CGFloat = {
			let le = leftEye.center; let re = rightEye.center
			let v = CGVector(dx: re.x - le.x, dy: re.y - le.y)
			return atan2(abs(v.dy), abs(v.dx)) * 180 / .pi
		}()
		let mmPerPx = CGFloat(CalibrationManager.shared.state.scaleMMPerPixel ?? 1.0)
		let nasalWidth: CGFloat = {
			let lx = nose.min(by: { $0.x < $1.x })?.x ?? 0
			let rx = nose.max(by: { $0.x < $1.x })?.x ?? 0
			let px = max(0.0, rx - lx)
			return px * imageSize.width * mmPerPx
		}()
		let lowerFaceAngle: CGFloat = {
			guard faceContour.count > 2 else { return 0 }
			let chin = faceContour.max(by: { $0.y < $1.y }) ?? .zero
			let jawL = faceContour.first ?? .zero
			let jawR = faceContour.last ?? .zero
			let v1 = CGVector(dx: jawL.x - chin.x, dy: jawL.y - chin.y)
			let v2 = CGVector(dx: jawR.x - chin.x, dy: jawR.y - chin.y)
			let c = max(-1, min(1, (v1.dx*v2.dx + v1.dy*v2.dy) / (hypot(v1.dx, v1.dy)*hypot(v2.dx, v2.dy) + 1e-6)))
			return acos(c) * 180 / .pi
		}()
		let lipCurvature: CGFloat = {
			guard outerLips.count > 2 else { return 0 }
			let left = outerLips.min(by: { $0.x < $1.x }) ?? .zero
			let right = outerLips.max(by: { $0.x < $1.x }) ?? .zero
			let top = outerLips.min(by: { $0.y < $1.y }) ?? .zero
			let base = CGVector(dx: right.x - left.x, dy: right.y - left.y)
			let apex = CGVector(dx: top.x - left.x, dy: top.y - left.y)
			let c = max(-1, min(1, (base.dx*apex.dx + base.dy*apex.dy) / (hypot(base.dx, base.dy)*hypot(apex.dx, apex.dy) + 1e-6)))
			return acos(c) * 180 / .pi
		}()

		// 额外毫米指标（可选）
		let intercanthalMM: CGFloat? = {
			guard let lePts = points["leftEye"], let rePts = points["rightEye"], !lePts.isEmpty, !rePts.isEmpty else { return nil }
			let leftInnerX = lePts.max(by: { $0.x < $1.x })?.x ?? lePts.center.x
			let rightInnerX = rePts.min(by: { $0.x < $1.x })?.x ?? rePts.center.x
			let px = max(0, (rightInnerX - leftInnerX) * imageSize.width)
			return px * mmPerPx
		}()
		let browEyeMM: CGFloat? = {
			guard let browL = points["leftEyebrow"], let lePts = points["leftEye"], !browL.isEmpty, !lePts.isEmpty else { return nil }
			let browY = browL.center.y * imageSize.height
			let eyeY = lePts.center.y * imageSize.height
			return abs(browY - eyeY) * mmPerPx
		}()
		let palpebralMM: CGFloat? = {
			guard let lePts = points["leftEye"], !lePts.isEmpty else { return nil }
			let top = lePts.min(by: { $0.y < $1.y })?.y ?? lePts.center.y
			let bottom = lePts.max(by: { $0.y < $1.y })?.y ?? lePts.center.y
			let px = max(0, (bottom - top) * imageSize.height)
			return px * mmPerPx
		}()

		return AestheticsMetrics(
			threeFacialZonesRatio: threeZones,
			fiveEyesRatio: fiveEyes,
			nasolabialAngleDegrees: angle,
			chinProjectionRatio: chinProjection,
			faceWidthToHeight: faceWH,
			innerCanthusAngleDeg: innerCanthusAngle,
			nasalWidthMM: nasalWidth,
			lowerFaceAngleDeg: lowerFaceAngle,
			lipCurvatureDeg: lipCurvature,
			intercanthalDistanceMM: intercanthalMM,
			browToEyeDistanceMM: browEyeMM,
			palpebralFissureHeightMM: palpebralMM,
			mandibularAngleDegrees: lowerFaceAngle
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


