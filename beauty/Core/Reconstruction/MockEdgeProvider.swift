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
        // Fallback: head-like spherical mesh (visible and smooth), not a quad
        let radius: Float = 90
        var verts: [SIMD3<Float>] = []
        var faces: [SIMD3<UInt32>] = []
        let step = Float.pi/18 // 10°
        var rowStarts: [Int] = []
        for phi in stride(from: -Float.pi/2, through: Float.pi/2, by: step) {
            rowStarts.append(verts.count)
            for theta in stride(from: 0, through: 2*Float.pi, by: step) {
                let x = radius * cos(phi) * cos(theta)
                let y = radius * sin(phi)
                let z = radius * cos(phi) * sin(theta)
                verts.append(SIMD3<Float>(x, y, z))
            }
        }
        let cols = Int(2*Float.pi/step) + 1
        let rows = Int((Float.pi/step)) + 1
        for r in 0..<(rows-1) {
            for c in 0..<(cols-1) {
                let i = UInt32(r*cols + c)
                faces.append(SIMD3<UInt32>(i, i+1, i+UInt32(cols)))
                faces.append(SIMD3<UInt32>(i+1, i+UInt32(cols)+1, i+UInt32(cols)))
            }
        }
        let texSize = CGSize(width: 16, height: 16)
        let tex = UIGraphicsImageRenderer(size: texSize).image { ctx in
            UIColor(white: 0.9, alpha: 1).setFill(); ctx.fill(CGRect(origin: .zero, size: texSize))
        }
        return FaceMesh3D(vertices: verts, faces: faces, uvs: nil, albedo: tex, mmPerPixel: CalibrationManager.shared.state.scaleMMPerPixel)
    }
}



