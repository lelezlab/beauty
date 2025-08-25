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
        // vertices may be an Array of simd_float3 on modern SDKs
        let verts: [SIMD3<Float>] = g.vertices.map { v in SIMD3<Float>(v.x, v.y, v.z) }
        // triangleIndices may be [Int16]; convert to UInt16
        let indicesU16: [UInt16] = g.triangleIndices.map { UInt16(bitPattern: $0) }
        let triCount = indicesU16.count / 3
        lastGeometry = (verts, indicesU16, triCount)
    }

    func clear() { lastGeometry = nil }

    // Allow setting from mock/pipeline for offline diagnostics
    func setFromMock(vertices: [SIMD3<Float>], indices: [UInt16], triCount: Int) {
        lastGeometry = (vertices, indices, triCount)
    }
}


