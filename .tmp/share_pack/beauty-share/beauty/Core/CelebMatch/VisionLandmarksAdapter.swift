import CoreGraphics
#if canImport(Vision)
import Vision
import UIKit

enum VisionLandmarksAdapter {
    static func fivePoint(from obs: VNFaceObservation, in imageSize: CGSize) -> FivePoint? {
        guard let lmk = obs.landmarks else { return nil }
        func denorm(_ p: CGPoint) -> CGPoint {
            let bb = obs.boundingBox
            let x = (bb.origin.x + p.x * bb.size.width) * imageSize.width
            let y = (1 - (bb.origin.y + p.y * bb.size.height)) * imageSize.height
            return CGPoint(x: x, y: y)
        }
        // 眼中心
        let leftEyePts  = (lmk.leftEye?.normalizedPoints ?? []) + (lmk.leftPupil?.normalizedPoints ?? [])
        let rightEyePts = (lmk.rightEye?.normalizedPoints ?? []) + (lmk.rightPupil?.normalizedPoints ?? [])
        guard !leftEyePts.isEmpty, !rightEyePts.isEmpty else { return nil }
        let le = leftEyePts.reduce(CGPoint.zero){ CGPoint(x:$0.x+CGFloat($1.x), y:$0.y+CGFloat($1.y)) }.applying(.init(scaleX: 1/CGFloat(leftEyePts.count), y: 1/CGFloat(leftEyePts.count)))
        let re = rightEyePts.reduce(CGPoint.zero){ CGPoint(x:$0.x+CGFloat($1.x), y:$0.y+CGFloat($1.y)) }.applying(.init(scaleX: 1/CGFloat(rightEyePts.count), y: 1/CGFloat(rightEyePts.count)))
        let nosePts = (lmk.nose?.normalizedPoints ?? []) + (lmk.noseCrest?.normalizedPoints ?? [])
        guard let noseN = nosePts.max(by: { $0.y < $1.y }) else { return nil }
        guard let mouth = lmk.outerLips ?? lmk.innerLips else { return nil }
        guard let ml = mouth.normalizedPoints.min(by: { $0.x < $1.x }), let mr = mouth.normalizedPoints.max(by: { $0.x < $1.x }) else { return nil }
        return FivePoint(leftEye: denorm(le), rightEye: denorm(re), nose: denorm(CGPoint(x: CGFloat(noseN.x), y: CGFloat(noseN.y))), mouthLeft: denorm(CGPoint(x: CGFloat(ml.x), y: CGFloat(ml.y))), mouthRight: denorm(CGPoint(x: CGFloat(mr.x), y: CGFloat(mr.y))))
    }
}
#endif


