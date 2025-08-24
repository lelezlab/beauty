import Foundation
import simd

struct OBJMesh {
    let vertices: [SIMD3<Float>]
    let faces: [SIMD3<UInt32>]
}

enum OBJParser {
    static func load(url: URL) -> OBJMesh? {
        guard let text = try? String(contentsOf: url) else { return nil }
        var verts: [SIMD3<Float>] = []
        var faces: [SIMD3<UInt32>] = []
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            if line.hasPrefix("v ") {
                let parts = line.split(separator: " ").map(String.init)
                if parts.count >= 4, let x = Float(parts[1]), let y = Float(parts[2]), let z = Float(parts[3]) {
                    verts.append(SIMD3<Float>(x,y,z))
                }
            } else if line.hasPrefix("f ") {
                // faces may look like: f 1 2 3 or f 1/1/1 2/2/2 3/3/3
                let comps = line.split(separator: " ")
                if comps.count >= 4 {
                    let idx: [UInt32] = comps.dropFirst().prefix(3).compactMap { token in
                        let s = String(token)
                        if let i = UInt32(s.split(separator: "/").first ?? Substring("0")) { return i-1 }
                        return nil
                    }
                    if idx.count == 3 { faces.append(SIMD3<UInt32>(idx[0], idx[1], idx[2])) }
                }
            }
        }
        return OBJMesh(vertices: verts, faces: faces)
    }
}


