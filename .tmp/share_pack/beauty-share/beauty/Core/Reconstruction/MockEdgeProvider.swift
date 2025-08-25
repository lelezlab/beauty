import Foundation
import UIKit

enum MockEdgeProvider {
    static func reconstructDemo(bundle: CaptureBundle) async throws -> FaceMesh3D {
        // Prefer loading a face-like OBJ so预览不是球体
        if let objURL = Bundle.main.url(forResource: "specs/golden_mask/golden_mask_3d", withExtension: "obj"),
           let gm = OBJParser.load(url: objURL) {
            // Scale normalized obj to approximate real size (mm)
            let scale: Float = 95
            let verts = gm.vertices.map { SIMD3<Float>($0.x * scale, $0.y * scale, $0.z * scale) }
            let faces = gm.faces
            let size = CGSize(width: 8, height: 8)
            let tex = UIGraphicsImageRenderer(size: size).image { ctx in UIColor.white.setFill(); ctx.fill(CGRect(origin: .zero, size: size)) }
            var mesh = FaceMesh3D(vertices: verts, faces: faces, uvs: nil, albedo: tex, mmPerPixel: CalibrationManager.shared.state.scaleMMPerPixel)
            mesh.topologyId = "GOLDEN_MASK_OBJ"
            mesh.metadata = ["source": "mock_edge_face"]
            return mesh
        }
        // Fallback: small quad (should rarely hit)
        let verts: [SIMD3<Float>] = [SIMD3(-50, -50, 50), SIMD3(50, -50, 50), SIMD3(-50, 50, 50), SIMD3(50, 50, 50)]
        let faces: [SIMD3<UInt32>] = [SIMD3(0,1,2), SIMD3(1,3,2)]
        let uvs: [SIMD2<Float>] = [SIMD2(0,0), SIMD2(1,0), SIMD2(0,1), SIMD2(1,1)]
        return FaceMesh3D(vertices: verts, faces: faces, uvs: uvs, albedo: nil, mmPerPixel: CalibrationManager.shared.state.scaleMMPerPixel)
    }
}



