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


