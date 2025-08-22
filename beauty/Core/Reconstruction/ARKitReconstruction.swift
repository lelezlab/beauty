import Foundation
import ARKit
import simd
import UIKit

final class ARKitReconstruction: ReconstructionProvider {
    func reconstruct(from bundle: CaptureBundle) async throws -> FaceMesh3D {
        guard ARFaceTrackingConfiguration.isSupported else {
            throw NSError(domain: "ARKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Face tracking not supported"])
        }

        guard let geo = ARFaceGeometryCache.shared.lastGeometry else {
            throw NSError(domain: "ARKit", code: -2, userInfo: [NSLocalizedDescriptionKey: "No face geometry captured"])
        }

        // Convert to millimeters for downstream metrics; SceneKit will convert back to meters in renderer
        let verticesMM: [SIMD3<Float>] = geo.vertices.map { SIMD3<Float>($0.x * 1000.0, $0.y * 1000.0, $0.z * 1000.0) }
        let indices: [SIMD3<UInt32>] = stride(from: 0, to: geo.triangleCount * 3, by: 3).map {
            SIMD3<UInt32>(UInt32(geo.triangleIndices[$0]), UInt32(geo.triangleIndices[$0 + 1]), UInt32(geo.triangleIndices[$0 + 2]))
        }

        let template = try UnifiedRetopo.loadTemplate()
        let (retopoVerts, uvs) = UnifiedRetopo.retopologize(vertices: verticesMM, indices: indices, to: template)

        var mesh = FaceMesh3D(
            vertices: retopoVerts,
            faces: template.indices ?? [],
            uvs: uvs,
            albedo: nil,
            mmPerPixel: bundle.calibrationMMPerPX != nil ? Double(bundle.calibrationMMPerPX!) : nil,
            normals: nil,
            indices: template.indices,
            topologyId: template.topologyId,
            calibrationMMPerPX: bundle.calibrationMMPerPX,
            neutralPoseCoeffs: nil,
            metadata: ["source": "arkit"]
        )

        try? TextureBaker.bake(bundle: bundle, mesh: &mesh, options: .init())
        return mesh
    }
}

import Foundation
@_exported import ARKit
import UIKit
import simd

final class ARKitReconstruction: ReconstructionProvider {
    init() {}
    func reconstruct(from bundle: CaptureBundle) async throws -> FaceMesh3D {
        // Placeholder: return a unit sphere-like mesh as stub
        var verts: [SIMD3<Float>] = []
        var faces: [SIMD3<UInt32>] = []
        let n = 16
        for i in 0...n {
            let theta = Float.pi * Float(i) / Float(n)
            for j in 0..<n*2 {
                let phi = 2*Float.pi * Float(j) / Float(2*n)
                let x = sin(theta)*cos(phi)
                let y = cos(theta)
                let z = sin(theta)*sin(phi)
                verts.append(SIMD3<Float>(x, y, z))
            }
        }
        // crude triangulation
        let ring = Int(2*n)
        for i in 0..<n { for j in 0..<ring {
            let a = UInt32(i*ring + j)
            let b = UInt32(i*ring + (j+1)%ring)
            let c = UInt32((i+1)*ring + j)
            let d = UInt32((i+1)*ring + (j+1)%ring)
            faces.append(SIMD3<UInt32>(a,b,c))
            faces.append(SIMD3<UInt32>(b,d,c))
        }}
        var mesh = FaceMesh3D(vertices: verts, faces: faces, uvs: nil, albedo: nil, mmPerPixel: nil)
        mesh.mmPerPixel = CalibrationManager.shared.state.scaleMMPerPixel
        return mesh
    }
}


