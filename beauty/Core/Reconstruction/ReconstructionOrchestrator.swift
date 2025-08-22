import Foundation
import UIKit

enum ReconstructionBackend {
    case arkit
    case decaEdge
}

final class ReconstructionOrchestrator {
    static let shared = ReconstructionOrchestrator()
    private init() {}

    func buildBundleFromCapture() -> CaptureBundle {
        let camera = CaptureBundle.CameraParams(
            focalEqMM: CaptureStore.shared.frontImage != nil ? CameraSession().focalEqMM : nil,
            fovDegrees: CameraSession().fieldOfViewDegrees,
            aeLocked: CameraSession().aeLocked,
            awbLocked: CameraSession().awbLocked,
            rollDegrees: CameraSession().levelDegrees
        )
        var ipd: Double? = nil
        var norm: [String: [[Double>]]? = nil
        if let lm = CaptureStore.shared.frontLandmarks, let res = LandmarkNormalizer.normalize(points: lm.points) {
            ipd = res.ipd
            norm = res.norm
        }
        let b = CaptureBundle(front: CaptureStore.shared.frontImage,
                               left: CaptureStore.shared.leftImage,
                               right: CaptureStore.shared.rightImage,
                               videoURL: nil,
                               rawLandmarks: CaptureStore.shared.frontLandmarks,
                               normalizedLandmarks: norm,
                               ipdNorm: ipd,
                               camera: camera,
                               qc: BeautyTelemetryService.shared.lastQC)
        return b
    }

    func provider(for backend: ReconstructionBackend) -> ReconstructionProvider {
        switch backend {
        case .arkit: return ARKitReconstruction()
        case .decaEdge: return DECAEdgeReconstruction()
        }
    }

    func reconstruct(backend: ReconstructionBackend = .arkit) async -> FaceMesh3D? {
        let bundle = buildBundleFromCapture()
        let prov = provider(for: backend)
        do {
            var mesh = try await prov.reconstruct(from: bundle)
            mesh.mmPerPixel = mesh.mmPerPixel ?? CalibrationManager.shared.state.scaleMMPerPixel
            CaptureStore.shared.lastMesh = mesh
            return mesh
        } catch {
            print("reconstruct error: \(error)")
            return nil
        }
    }
}


