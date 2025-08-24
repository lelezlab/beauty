import Foundation
import UIKit
import simd

struct CaptureBundle {
    struct CameraParams: Codable {
        var focalEqMM: Double?
        var fovDegrees: Double?
        var aeLocked: Bool?
        var awbLocked: Bool?
        var rollDegrees: Double?
    }
    var front: UIImage?
    var left: UIImage?
    var right: UIImage?
    var videoURL: URL?
    var rawLandmarks: FacialLandmarksResult?
    var normalizedLandmarks: [String: [[Double]] ]?
    var ipdNorm: Double?
    var camera: CameraParams?
    var qc: BTCaptureQC?
    // Round 5 additions (optionals to preserve compatibility)
    var intrinsics: simd_float3x3?
    var poses: [simd_float4x4]?
    var qualityScore: Float?
    var selectedFrameIndices: [Int]?
    init(front: UIImage?, left: UIImage?, right: UIImage?, videoURL: URL?, rawLandmarks: FacialLandmarksResult?, normalizedLandmarks: [String: [[Double]] ]?, ipdNorm: Double?, camera: CameraParams?, qc: BTCaptureQC?) {
        self.front = front; self.left = left; self.right = right; self.videoURL = videoURL
        self.rawLandmarks = rawLandmarks
        self.normalizedLandmarks = normalizedLandmarks
        self.ipdNorm = ipdNorm
        self.camera = camera
        self.qc = qc
    }
}

struct FaceMesh3D {
    var vertices: [SIMD3<Float>]
    var faces: [SIMD3<UInt32>]
    var uvs: [SIMD2<Float>]? 
    var albedo: UIImage?
    var mmPerPixel: Double?
    // Round 5 extensions (optionals to avoid breaking existing code)
    var normals: [SIMD3<Float>]? // aligned with vertices
    var indices: [SIMD3<UInt32>]? // alias for faces, if provided
    var topologyId: String?
    var calibrationMMPerPX: Float?
    var neutralPoseCoeffs: [String: Float]? // expression-neutralized coefficients
    var metadata: [String: Any]? // anchors3d, debug info, etc.
}

extension FaceMesh3D {
    /// Return a deformed mesh by simple parameter mapping (demo):
    /// - tip_rotation (deg): small rotation around tip region's local Y
    /// - bridge_straighten (0..1): pull dorsum vertices towards best-fit line
    func deformed(by params: [String: Double]) -> FaceMesh3D {
        guard !vertices.isEmpty else { return self }
        var out = self
        var vs = vertices
        // Derive a rough dorsum/ tip ROI from metadata anchors if available
        let tipIndex: Int? = (metadata?["anchors3d"] as? [String:Int])?["pronasale"]
        let nasionIndex: Int? = (metadata?["anchors3d"] as? [String:Int])?["nasion"]
        if let tdeg = params["tip_rotation"], let tip = tipIndex {
            let rad = Float((tdeg) * .pi / 180.0)
            let s = sin(rad), c = cos(rad)
            let center = vs[tip]
            for i in 0..<vs.count {
                var p = vs[i] - center
                // rotate around local Y (approx.)
                let nx =  c*p.x + s*p.z
                let nz = -s*p.x + c*p.z
                p.x = nx; p.z = nz
                vs[i] = p + center
            }
        }
        if let amt = params["bridge_straighten"], amt > 0.0001, let a = nasionIndex, let b = tipIndex {
            let pa = vs[a], pb = vs[b]
            let dir = simd_normalize(pb - pa)
            for i in 0..<vs.count {
                var p = vs[i]
                // project p onto line pa->pb then blend towards it
                let t = simd_dot(p - pa, dir)
                let proj = pa + t*dir
                p = simd_mix(p, proj, SIMD3<Float>(repeating: Float(amt)))
                vs[i] = p
            }
        }
        out.vertices = vs
        return out
    }
    /// Linear blend between original and after mesh for before/after slider
    static func blend(_ a: FaceMesh3D, _ b: FaceMesh3D, t: Float) -> FaceMesh3D {
        let n = min(a.vertices.count, b.vertices.count)
        var v: [SIMD3<Float>] = a.vertices
        if n > 0 {
            v = (0..<n).map { simd_mix(a.vertices[$0], b.vertices[$0], SIMD3<Float>(repeating: t)) }
        }
        return FaceMesh3D(vertices: v, faces: a.faces, uvs: a.uvs ?? b.uvs, albedo: a.albedo ?? b.albedo, mmPerPixel: a.mmPerPixel ?? b.mmPerPixel, normals: a.normals ?? b.normals, indices: a.indices ?? b.indices, topologyId: a.topologyId ?? b.topologyId, calibrationMMPerPX: a.calibrationMMPerPX ?? b.calibrationMMPerPX, neutralPoseCoeffs: a.neutralPoseCoeffs ?? b.neutralPoseCoeffs, metadata: a.metadata ?? b.metadata)
    }
}

protocol ReconstructionProvider {
    func reconstruct(from bundle: CaptureBundle) async throws -> FaceMesh3D
}

enum ReconstructionFactory {
    static func makeDefault() -> ReconstructionProvider {
        #if canImport(ARKit)
        return ARKitReconstruction()
        #else
        return StubReconstructionProvider()
        #endif
    }
}

#if !canImport(ARKit)
public final class StubReconstructionProvider: ReconstructionProvider {
    public init() {}
    public func reconstruct(from bundle: CaptureBundle) async throws -> FaceMesh3D {
        return FaceMesh3D(vertices: [], faces: [], uvs: nil, albedo: nil, mmPerPixel: CalibrationManager.shared.state.scaleMMPerPixel)
    }
}
#endif


