import Foundation
import UIKit
import simd

public struct CaptureBundle {
    public struct CameraParams: Codable {
        public var focalEqMM: Double?
        public var fovDegrees: Double?
        public var aeLocked: Bool?
        public var awbLocked: Bool?
        public var rollDegrees: Double?
    }
    public var front: UIImage?
    public var left: UIImage?
    public var right: UIImage?
    public var videoURL: URL?
    public var rawLandmarks: FacialLandmarksResult?
    public var normalizedLandmarks: [String: [[Double]] ]?
    public var ipdNorm: Double?
    public var camera: CameraParams?
    public var qc: BTCaptureQC?
    public init(front: UIImage?, left: UIImage?, right: UIImage?, videoURL: URL?, rawLandmarks: FacialLandmarksResult?, normalizedLandmarks: [String: [[Double]] ]?, ipdNorm: Double?, camera: CameraParams?, qc: BTCaptureQC?) {
        self.front = front; self.left = left; self.right = right; self.videoURL = videoURL
        self.rawLandmarks = rawLandmarks
        self.normalizedLandmarks = normalizedLandmarks
        self.ipdNorm = ipdNorm
        self.camera = camera
        self.qc = qc
    }
}

public struct FaceMesh3D {
    public var vertices: [SIMD3<Float>]
    public var faces: [SIMD3<UInt32>]
    public var uvs: [SIMD2<Float>]?
    public var albedo: UIImage?
    public var mmPerPixel: Double?
}

public protocol ReconstructionProvider {
    func reconstruct(from bundle: CaptureBundle) async throws -> FaceMesh3D
}

public enum ReconstructionFactory {
    public static func makeDefault() -> ReconstructionProvider {
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


