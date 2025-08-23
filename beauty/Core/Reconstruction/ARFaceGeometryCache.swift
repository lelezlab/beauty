import Foundation
import ARKit
import simd

final class ARFaceGeometryCache {
    static let shared = ARFaceGeometryCache()
    private init() {}

    // Store last captured face geometry (in meters as provided by ARKit)
    private(set) var lastGeometry: (vertices: [SIMD3<Float>], triangleIndices: [UInt16], triangleCount: Int)?

    func update(from anchor: ARFaceAnchor) {
        let g = anchor.geometry
        let verts: [SIMD3<Float>] = (0..<Int(g.vertexCount)).map { i in
            let v = g.vertices[i]
            return SIMD3<Float>(v.x, v.y, v.z)
        }
        let triCount = Int(g.triangleCount)
        let idxBuffer = g.triangleIndices
        let indices = Array(UnsafeBufferPointer(start: idxBuffer, count: triCount * 3))
        lastGeometry = (verts, indices, triCount)
    }

    func clear() { lastGeometry = nil }
}


