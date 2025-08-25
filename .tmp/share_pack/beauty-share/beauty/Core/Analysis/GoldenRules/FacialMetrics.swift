import Foundation
import CoreGraphics

struct FacialMetrics: Codable {
    var threeZones: Double?
    var fiveEyes: Double?
    var nasolabialDeg: Double?
    var nasofrontalDeg: Double?
    var symmetry: Double?
}

enum FacialMetricsCalculator {
    static func compute(from landmarks: [String: [CGPoint]]) -> FacialMetrics {
        var m = FacialMetrics()
        if let browToNasal = angleDeg(landmarks["glabella"], landmarks["nasion"], landmarks["pronasale"]) {
            m.nasofrontalDeg = browToNasal
        }
        if let columella = angleDeg(landmarks["subnasale"], landmarks["columella"], landmarks["labialeSuperius"]) {
            m.nasolabialDeg = columella
        }
        if let left = landmarks["leftEye"], let right = landmarks["rightEye"], let face = landmarks["face"] {
            m.fiveEyes = fiveEyesRatio(leftEye: left, rightEye: right, face: face)
        }
        if let face = landmarks["face"], let nose = landmarks["nose"] {
            m.threeZones = threeZonesRatio(face: face, nose: nose)
        }
        m.symmetry = symmetryScore(landmarks)
        return m
    }

    private static func fiveEyesRatio(leftEye: [CGPoint], rightEye: [CGPoint], face: [CGPoint]) -> Double? {
        guard let l = centroid(leftEye), let r = centroid(rightEye) else { return nil }
        let eyeWidth = averageWidth(eye: leftEye) + averageWidth(eye: rightEye)
        let spacing = abs(Double(r.x - l.x)) - eyeWidth/2.0
        let faceWidth = faceWidthPx(face)
        guard faceWidth > 1 else { return nil }
        return spacing * 5.0 / faceWidth
    }

    private static func threeZonesRatio(face: [CGPoint], nose: [CGPoint]) -> Double? {
        // placeholder: vertical thirds by key anchors
        guard let top = face.min(by: { $0.y < $1.y }), let bottom = face.max(by: { $0.y < $1.y }), let n = centroid(nose) else { return nil }
        let total = Double(bottom.y - top.y)
        guard total > 1 else { return nil }
        let upper = Double(n.y - top.y)
        return min(max(upper / (total/3.0), 0), 3)
    }

    private static func symmetryScore(_ lm: [String: [CGPoint]]) -> Double? {
        guard let face = lm["face"], !face.isEmpty else { return nil }
        let xs = face.map { Double($0.x) }
        guard let minX = xs.min(), let maxX = xs.max() else { return nil }
        let mid = (minX + maxX)/2.0
        let left = face.filter { Double($0.x) < mid }
        let right = face.filter { Double($0.x) >= mid }
        guard left.count > 0, right.count > 0 else { return nil }
        let dl = left.map { abs(Double($0.x) - mid) }.reduce(0,+)/Double(left.count)
        let dr = right.map { abs(Double($0.x) - mid) }.reduce(0,+)/Double(right.count)
        let denom = max(dl, dr)
        return denom > 0 ? 1.0 - abs(dl - dr)/denom : 1.0
    }

    private static func centroid(_ pts: [CGPoint]) -> CGPoint? {
        guard !pts.isEmpty else { return nil }
        let sx = pts.map { $0.x }.reduce(0,+)
        let sy = pts.map { $0.y }.reduce(0,+)
        return CGPoint(x: sx/CGFloat(pts.count), y: sy/CGFloat(pts.count))
    }

    private static func averageWidth(eye: [CGPoint]) -> Double {
        guard let minX = eye.map({ $0.x }).min(), let maxX = eye.map({ $0.x }).max() else { return 0 }
        return Double(maxX - minX)
    }

    private static func faceWidthPx(_ face: [CGPoint]) -> Double {
        guard let minX = face.map({ $0.x }).min(), let maxX = face.map({ $0.x }).max() else { return 1 }
        return Double(maxX - minX)
    }

    private static func angleDeg(_ a: [CGPoint]?, _ b: [CGPoint]?, _ c: [CGPoint]?) -> Double? {
        guard let pa = a?.first, let pb = b?.first, let pc = c?.first else { return nil }
        let v1 = CGPoint(x: pa.x - pb.x, y: pa.y - pb.y)
        let v2 = CGPoint(x: pc.x - pb.x, y: pc.y - pb.y)
        let dot = Double(v1.x * v2.x + v1.y * v2.y)
        let m1 = sqrt(Double(v1.x*v1.x + v1.y*v1.y))
        let m2 = sqrt(Double(v2.x*v2.x + v2.y*v2.y))
        guard m1 > 1e-6 && m2 > 1e-6 else { return nil }
        let cosv = max(-1.0, min(1.0, dot/(m1*m2)))
        return acos(cosv) * 180.0 / .pi
    }
}


