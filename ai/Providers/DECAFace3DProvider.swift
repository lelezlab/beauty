import Foundation
import CoreGraphics

final class DECAFace3DProvider: Face3DProvider {
    let name = "deca_flame"
    private(set) var isReady = false
    private(set) var modelBytes: Int64?
    private(set) var loadLatencyMS: Int?

    func warmup() throws {
        let t0 = Date()
        let path = try ModelRegistry.path(for: "deca")
        let attr = try FileManager.default.attributesOfItem(atPath: path)
        self.modelBytes = (attr[.size] as? NSNumber)?.int64Value
        self.loadLatencyMS = Int(Date().timeIntervalSince(t0) * 1000)
        self.isReady = true
    }

    func reconstruct(triViews: [CGImage]) throws -> FaceMesh3D {
        precondition(isReady, "call warmup() first")
        return FaceMesh3D(vertices: [], faces: [], uvs: nil, albedo: nil, mmPerPixel: nil, normals: nil, indices: nil, topologyId: nil, calibrationMMPerPX: nil, neutralPoseCoeffs: nil, metadata: ["source": "deca"])
    }
}


