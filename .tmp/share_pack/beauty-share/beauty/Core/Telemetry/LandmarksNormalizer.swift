import Foundation
import CoreGraphics

enum LandmarksNormalizer {
    static func normalize468(points: [CGPoint], leftEye: [CGPoint], rightEye: [CGPoint]) -> (ipdPx: Double, normalized: [[Double]])? {
        guard let lc = centroid(leftEye), let rc = centroid(rightEye) else { return nil }
        let ipd = hypot(Double(lc.x - rc.x), Double(lc.y - rc.y))
        guard ipd > 1e-6 else { return nil }
        let norm = points.map { p -> [Double] in
            let dx = (Double(p.x) - Double(lc.x)) / ipd
            let dy = (Double(p.y) - Double(lc.y)) / ipd
            return [Double(round(dx*1000)/1000), Double(round(dy*1000)/1000)]
        }
        return (ipd, norm)
    }

    private static func centroid(_ pts: [CGPoint]) -> CGPoint? {
        guard !pts.isEmpty else { return nil }
        let sx = pts.map { $0.x }.reduce(0,+)
        let sy = pts.map { $0.y }.reduce(0,+)
        return CGPoint(x: sx/CGFloat(pts.count), y: sy/CGFloat(pts.count))
    }
}


