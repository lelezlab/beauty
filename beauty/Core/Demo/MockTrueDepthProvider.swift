import Foundation
import simd
import UIKit

enum MockTrueDepthProvider {
    static func loadMesh() async throws -> FaceMesh3D {
        // Minimal placeholder: generate an icosphere-ish quad as demo if asset missing
        let verts: [SIMD3<Float>] = [SIMD3(-50, -50, 50), SIMD3(50, -50, 50), SIMD3(-50, 50, 50), SIMD3(50, 50, 50)]
        let faces: [SIMD3<UInt32>] = [SIMD3(0,1,2), SIMD3(1,3,2)]
        let uvs: [SIMD2<Float>] = [SIMD2(0,0), SIMD2(1,0), SIMD2(0,1), SIMD2(1,1)]
        return FaceMesh3D(vertices: verts, faces: faces, uvs: uvs, albedo: nil, mmPerPixel: 0.1, normals: nil, indices: faces, topologyId: "MOCK_TD", calibrationMMPerPX: 0.1, neutralPoseCoeffs: nil, metadata: ["source": "mock_td"])
    }
}


