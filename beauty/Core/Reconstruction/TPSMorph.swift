import Foundation
import simd

/// Lightweight TPS-like morpher with clinical safety bounds clamping.
/// This is a pragmatic implementation for the Doctor Mode vertical slice.
enum TPSMorph {
    struct Params {
        var tip_rotation: Double = 0.0      // degrees, [-10, 10]
        var bridge_straighten: Double = 0.0 // [0,1]
        var alar_narrowing: Double = 0.0    // [0,1]
        var chin_forward: Double = 0.0      // mm
        var gonial_angle_soften: Double = 0.0 // [0,1]
    }

    /// Clamp a value according to clinical rules if present; fall back to provided soft/hard defaults.
    static func clamp(metric: String, value: Double, soft: ClosedRange<Double>, hard: ClosedRange<Double>) -> Double {
        if let r = RulesStore.shared.byMetric[metric] {
            let hmin = r.hard_min ?? hard.lowerBound
            let hmax = r.hard_max ?? hard.upperBound
            return min(max(value, hmin), hmax)
        }
        return min(max(value, hard.lowerBound), hard.upperBound)
    }

    /// Apply morph on mesh vertices with bounded parameters. Keeps topology.
    static func apply(to mesh: FaceMesh3D, params: Params) -> FaceMesh3D {
        var bounded = params
        bounded.tip_rotation = clamp(metric: "tip_rotation", value: params.tip_rotation, soft: -8...8, hard: -12...12)
        bounded.bridge_straighten = clamp(metric: "bridge_straighten", value: params.bridge_straighten, soft: 0...0.6, hard: 0...1)
        bounded.alar_narrowing = clamp(metric: "alar_narrowing", value: params.alar_narrowing, soft: 0...0.5, hard: 0...1)
        bounded.chin_forward = clamp(metric: "chin_forward", value: params.chin_forward, soft: -3...5, hard: -5...7)
        bounded.gonial_angle_soften = clamp(metric: "gonial_angle_soften", value: params.gonial_angle_soften, soft: 0...0.4, hard: 0...1)

        var v = mesh.vertices

        // tip rotation around pronasale (if available)
        if bounded.tip_rotation != 0, let tip = (mesh.metadata?["anchors3d"] as? [String:Int])?["pronasale"] {
            let rad = Float(bounded.tip_rotation * .pi / 180.0)
            let s = sin(rad), c = cos(rad)
            let center = v[tip]
            for i in 0..<v.count {
                var p = v[i] - center
                let nx =  c*p.x + s*p.z
                let nz = -s*p.x + c*p.z
                p.x = nx; p.z = nz
                v[i] = p + center
            }
        }

        // bridge straighten along nasion->pronasale line
        if bounded.bridge_straighten > 0, let a = (mesh.metadata?["anchors3d"] as? [String:Int])?["nasion"], let b = (mesh.metadata?["anchors3d"] as? [String:Int])?["pronasale"] {
            let pa = v[a], pb = v[b]
            let dir = simd_normalize(pb - pa)
            let t = Float(bounded.bridge_straighten)
            for i in 0..<v.count {
                let p = v[i]
                let proj = pa + simd_dot(p - pa, dir) * dir
                v[i] = simd_mix(p, proj, SIMD3<Float>(repeating: t))
            }
        }

        // alar narrowing: pull lateral nose points inward (approximate using x coordinate falloff)
        if bounded.alar_narrowing > 0 {
            let t = Float(bounded.alar_narrowing)
            let maxX = v.map { abs($0.x) }.max() ?? 1
            for i in 0..<v.count {
                var p = v[i]
                let k = min(abs(p.x) / maxX, 1)
                p.x = simd_mix(p.x, p.x * (1 - 0.3 * k), t)
                v[i] = p
            }
        }

        // chin forward: translate gnathion region forward in +Z with radial falloff
        if bounded.chin_forward != 0, let gn = (mesh.metadata?["anchors3d"] as? [String:Int])?["gnathion"] {
            let center = v[gn]
            let radius: Float = 40
            for i in 0..<v.count {
                var p = v[i]
                let d = simd_length(p - center)
                let w = max(0, 1 - d / radius)
                p.z += Float(bounded.chin_forward) * w
                v[i] = p
            }
        }

        // gonial angle soften: slight upward Y translation near jaw corners (approx by y<0 region)
        if bounded.gonial_angle_soften > 0 {
            let t = Float(bounded.gonial_angle_soften)
            for i in 0..<v.count {
                var p = v[i]
                if p.y < 0 { p.y = simd_mix(p.y, p.y + 6, t) }
                v[i] = p
            }
        }

        var out = mesh
        out.vertices = v
        return out
    }
}


