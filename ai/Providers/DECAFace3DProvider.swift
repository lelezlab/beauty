import Foundation
import CoreGraphics
import simd

final class DECAFace3DProvider: Face3DProvider {
    let name = "deca_flame"
    private(set) var isReady = false
    private(set) var modelBytes: Int64?
    private(set) var loadLatencyMS: Int?

    func warmup() throws {
        let t0 = Date()
        let path = try ModelRegistry.path(for: ModelIDs.decaONNX)
        let attr = try FileManager.default.attributesOfItem(atPath: path)
        self.modelBytes = (attr[.size] as? NSNumber)?.int64Value
        self.loadLatencyMS = Int(Date().timeIntervalSince(t0) * 1000)
        self.isReady = true
    }

    func reconstruct(triViews: [CGImage]) throws -> FaceMesh3D {
        guard isReady else { throw AIErrors.notReady("deca") }
        let lat = 24, lon = 48
        var verts:[SIMD3<Float>] = []; var uvs:[SIMD2<Float>] = []; var idx:[Int32] = []
        for i in 0...lat {
            let v = Float(i) / Float(lat)
            let phi = v * Float.pi
            for j in 0...lon {
                let u = Float(j) / Float(lon)
                let theta = u * 2 * Float.pi
                let r: Float = 0.09
                let x = r * sin(phi) * cos(theta)
                let y = r * cos(phi)
                let z = r * sin(phi) * sin(theta)
                verts.append(SIMD3<Float>(x,y,z))
                uvs.append(SIMD2<Float>(u, 1.0 - v))
            }
        }
        for i in 0..<lat {
            for j in 0..<lon {
                let a = Int32(i*(lon+1)+j)
                let b = a + 1
                let c = Int32((i+1)*(lon+1)+j)
                let d = c + 1
                idx += [a,b,c, b,d,c]
            }
        }
        return FaceMesh3D(vertices: verts, faces: [], uvs: nil, albedo: nil, mmPerPixel: nil, normals: nil, indices: nil, topologyId: nil, calibrationMMPerPX: nil, neutralPoseCoeffs: nil, metadata: ["source": "placeholder-sphere"])        
    }
}


