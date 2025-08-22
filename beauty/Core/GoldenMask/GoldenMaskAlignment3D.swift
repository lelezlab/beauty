import Foundation
import simd
import UIKit

enum GoldenMaskAlignment3D {
    struct Similarity { let R: float3x3; let t: SIMD3<Float>; let s: Float }

    static func computeSimilarity(src: [SIMD3<Float>], dst: [SIMD3<Float>]) -> Similarity? {
        guard src.count == dst.count, src.count >= 3 else { return nil }
        let n = Float(src.count)
        let ms = src.reduce(SIMD3<Float>(0,0,0), +) / n
        let md = dst.reduce(SIMD3<Float>(0,0,0), +) / n
        let X = src.map { $0 - ms }
        let Y = dst.map { $0 - md }
        var cov = float3x3(0)
        for i in 0..<src.count { cov += outerProduct(Y[i], X[i]) / n }
        // SVD of cov = U S V^T
        let (U,S,V) = svd3x3(cov)
        var R = U * transpose(V)
        if det3x3(R) < 0 { var U2 = U; U2[2,2] *= -1; R = U2 * transpose(V) }
        let varX = X.reduce(Float(0)) { $0 + dot($1,$1) } / n
        let s = (S[0] + S[1] + S[2]) / varX
        let t = md - s * (R * ms)
        return .init(R: R, t: t, s: s)
    }

    static func colorize(golden: OBJMesh, user: FaceMesh3D, anchorsGolden: [String:Int]?, anchorsUser: [String:Int]?, t1: Float, t2: Float, alpha: Float) -> [SIMD4<Float>] {
        // 1) 选择锚点对
        var Gp: [SIMD3<Float>] = []
        var Up: [SIMD3<Float>] = []
        if let ag = anchorsGolden, let au = anchorsUser {
            let keys = Set(ag.keys).intersection(au.keys)
            for k in keys {
                if let gi = ag[k], gi < golden.vertices.count, let ui = au[k], ui < user.vertices.count {
                    Gp.append(golden.vertices[gi])
                    Up.append(user.vertices[ui])
                }
            }
        }
        // 2) 相似变换将 golden → user 坐标
        let T = computeSimilarity(src: Gp, dst: Up)
        let R = T?.R ?? float3x3(1)
        let s = T?.s ?? 1
        let t = T?.t ?? SIMD3<Float>(0,0,0)
        var aligned: [SIMD3<Float>] = golden.vertices.map { (s * (R * $0)) + t }
        // 3) 对每个 golden 顶点，找最近的 user 顶点并计算距离（mm）
        let userVerts = user.vertices
        var colors: [SIMD4<Float>] = Array(repeating: SIMD4<Float>(0,1,0,alpha), count: aligned.count)
        for i in 0..<aligned.count {
            let g = aligned[i]
            var best: Float = .greatestFiniteMagnitude
            for u in userVerts { best = min(best, length(g - u)) }
            let c: SIMD4<Float>
            if best <= t1 { c = SIMD4<Float>(0,1,0,alpha) }
            else if best <= t2 { c = SIMD4<Float>(1,1,0,alpha) }
            else { c = SIMD4<Float>(1,0,0,alpha) }
            colors[i] = c
        }
        return colors
    }
}

// MARK: - Small SVD helpers (approximate)
private func det3x3(_ m: float3x3) -> Float { simd_determinant(m) }
private func svd3x3(_ A: float3x3) -> (U: float3x3, S: SIMD3<Float>, V: float3x3) {
    // Use eigen decomposition of A^T A for V, then compute U = A V S^-1
    let ATA = transpose(A) * A
    let (V, evals) = eigenSymmetric3x3(ATA)
    let S = SIMD3<Float>(sqrt(max(evals.x,0)), sqrt(max(evals.y,0)), sqrt(max(evals.z,0)))
    var Sinv = float3x3(0)
    if S.x > 1e-6 { Sinv[0,0] = 1/S.x }
    if S.y > 1e-6 { Sinv[1,1] = 1/S.y }
    if S.z > 1e-6 { Sinv[2,2] = 1/S.z }
    let U = A * V * Sinv
    return (U,S,V)
}

private func eigenSymmetric3x3(_ A: float3x3) -> (V: float3x3, evals: SIMD3<Float>) {
    // Fallback numeric iteration (very small matrices) — simplified Jacobi
    var V = float3x3(1)
    var B = A
    for _ in 0..<12 {
        // find largest off-diagonal
        var p=0,q=1
        var maxv = abs(B[0,1])
        if abs(B[0,2])>maxv { maxv=abs(B[0,2]); p=0;q=2 }
        if abs(B[1,2])>maxv { maxv=abs(B[1,2]); p=1;q=2 }
        if maxv < 1e-6 { break }
        let phi = 0.5 * atan2(2*B[p,q], B[p,p]-B[q,q])
        var R = float3x3(1)
        R[p,p] = cos(phi); R[q,q] = cos(phi)
        R[p,q] = -sin(phi); R[q,p] = sin(phi)
        B = transpose(R) * B * R
        V = V * R
    }
    return (V, SIMD3<Float>(B[0,0],B[1,1],B[2,2]))
}


