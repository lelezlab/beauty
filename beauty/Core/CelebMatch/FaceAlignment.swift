import UIKit
import simd

enum FaceAlignment {
    static func similarityTransform(from src: [CGPoint], to dst: [CGPoint]) -> CGAffineTransform {
        precondition(src.count == 5 && dst.count == 5)
        let sx = src.map { Double($0.x) }, sy = src.map { Double($0.y) }
        let dx = dst.map { Double($0.x) }, dy = dst.map { Double($0.y) }
        let mean: ([Double]) -> Double = { arr in arr.reduce(0, +) / Double(arr.count) }
        let msx = mean(sx), msy = mean(sy), mdx = mean(dx), mdy = mean(dy)
        var X = zip(sx, sy).map { pair -> SIMD2<Double> in SIMD2<Double>(pair.0 - msx, pair.1 - msy) }
        var Y = zip(dx, dy).map { pair -> SIMD2<Double> in SIMD2<Double>(pair.0 - mdx, pair.1 - mdy) }

        var cov = double2x2(columns: (SIMD2<Double>(0,0), SIMD2<Double>(0,0)))
        for i in 0..<5 {
            let c0 = SIMD2<Double>(X[i].x * Y[i].x, X[i].y * Y[i].x)
            let c1 = SIMD2<Double>(X[i].x * Y[i].y, X[i].y * Y[i].y)
            cov += double2x2(columns: (c0, c1))
        }
        var U = double2x2(columns: (SIMD2<Double>(0,0), SIMD2<Double>(0,0)))
        var V = double2x2(columns: (SIMD2<Double>(0,0), SIMD2<Double>(0,0)))
        var S = SIMD2<Double>(0, 0)
        svd2x2(cov, &U, &S, &V)
        var R = U * V.transpose
        if det(R) < 0 { U[0,1] *= -1; U[1,1] *= -1; R = U * V.transpose }
        let varX = X.reduce(0) { $0 + ($1.x * $1.x + $1.y * $1.y) } / 5.0
        let scale = (S.x + S.y) / varX
        let t = SIMD2<Double>(mdx, mdy) - scale * (R * SIMD2<Double>(msx, msy))
        let a = CGFloat(scale * R[0,0]), b = CGFloat(scale * R[0,1])
        let c = CGFloat(scale * R[1,0]), d = CGFloat(scale * R[1,1])
        return CGAffineTransform(a: a, b: c, c: b, d: d, tx: CGFloat(t.x), ty: CGFloat(t.y))
    }

    static func align(_ image: UIImage, landmarks: FivePoint,
                      template: [CGPoint] = AlignTemplate.arcface112,
                      size: CGSize = .init(width: 112, height: 112)) -> UIImage? {
        let src = [landmarks.leftEye, landmarks.rightEye, landmarks.nose, landmarks.mouthLeft, landmarks.mouthRight]
        let T = similarityTransform(from: src, to: template)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            ctx.cgContext.concatenate(T.inverted())
            image.draw(at: .zero)
        }
    }
}

@inline(__always) func det(_ m: double2x2) -> Double { m[0,0]*m[1,1] - m[0,1]*m[1,0] }
func svd2x2(_ m: double2x2, _ U: inout double2x2, _ S: inout SIMD2<Double>, _ V: inout double2x2) {
    let a=m[0,0], b=m[0,1], c=m[1,0], d=m[1,1]
    let ATA = double2x2(columns: (SIMD2<Double>(a*a+c*c, a*b+c*d),
                                  SIMD2<Double>(a*b+c*d, b*b+d*d)))
    let tr = ATA[0,0]+ATA[1,1]
    let detA = ATA[0,0]*ATA[1,1]-ATA[0,1]*ATA[1,0]
    let tmp = sqrt(max(0,tr*tr/4 - detA))
    let s1 = sqrt(max(ATA[0,0]+ATA[1,1])/2 + tmp)
    let s2 = sqrt(max(ATA[0,0]+ATA[1,1])/2 - tmp)
    S = SIMD2<Double>(s1,s2)
    var v0 = SIMD2<Double>(ATA[0,1], s1*s1-ATA[0,0])
    if hypot(v0.x, v0.y) < 1e-9 { v0 = SIMD2<Double>(1,0) }
    v0 /= simd_length(v0)
    let v1 = SIMD2<Double>(-v0.y, v0.x)
    V = double2x2(columns: (SIMD2<Double>(v0.x, v0.y), SIMD2<Double>(v1.x, v1.y)))
    let VinvS = double2x2(columns: (SIMD2<Double>(v0.x/s1, v0.y/s1), SIMD2<Double>(v1.x/s2, v1.y/s2)))
    U = m * VinvS
}


