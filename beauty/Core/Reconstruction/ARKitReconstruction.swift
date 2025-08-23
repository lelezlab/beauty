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


