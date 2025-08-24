import Foundation
import UIKit
#if canImport(ARKit)
import ARKit
#endif

enum ReconstructionBackend {
    case arkit
    case decaEdge
    case threeDDFA
}

final class ReconstructionOrchestrator {
    static let shared = ReconstructionOrchestrator()
    private init() {}
    private var cancelled: Bool = false

    func cancelAll() {
        cancelled = true
        // Best-effort: cancel outstanding URLSession tasks
        URLSession.shared.invalidateAndCancel()
    }

    func buildBundleFromCapture() -> CaptureBundle {
        let camera = CaptureBundle.CameraParams(
            focalEqMM: CaptureStore.shared.frontImage != nil ? CameraSession().focalEqMM : nil,
            fovDegrees: CameraSession().fieldOfViewDegrees,
            aeLocked: CameraSession().aeLocked,
            awbLocked: CameraSession().awbLocked,
            rollDegrees: CameraSession().levelDegrees
        )
        var ipd: Double? = nil
        var norm: [String: [[Double]]]? = nil
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
        case .decaEdge: return EdgeReconstruction() // use tri-view edge client with placeholder fallback
        case .threeDDFA: return ThreeDDFAReconstruction()
        }
    }

    func reconstruct(backend: ReconstructionBackend = .arkit) async -> FaceMesh3D? {
        if AppFlags.isProofRunning || cancelled { return nil }
        let bundle = buildBundleFromCapture()
        let prov = provider(for: backend)
        do {
            DebugLog.log("reconstruct begin: \(backend)")
            var mesh = try await prov.reconstruct(from: bundle)
            mesh.mmPerPixel = mesh.mmPerPixel ?? CalibrationManager.shared.state.scaleMMPerPixel
            CaptureStore.shared.lastMesh = mesh
            UserDefaults.standard.set(true, forKey: "last_recon_ok")
            DebugLog.log("reconstruct success: \(backend), verts=\(mesh.vertices.count)")
            return mesh
        } catch {
            print("reconstruct error: \(error)")
            DebugLog.log("reconstruct error: \(backend) -> \(error.localizedDescription)")
            UserDefaults.standard.set(false, forKey: "last_recon_ok")
            return nil
        }
    }

    // Auto: tri-view preferred when forced or when ARKit unsupported
    func reconstructAuto() async -> FaceMesh3D? {
        if AppFlags.isProofRunning || cancelled { return nil }
        let bundle = buildBundleFromCapture()
        let arkitAvailable: Bool = {
            #if canImport(ARKit)
            return ARFaceTrackingConfiguration.isSupported
            #else
            return false
            #endif
        }()
        if AppDebugFlags.forceTriView || !arkitAvailable {
            // Prefer RemoteEdge; fallback to 3DDFA; then ARKit
            do { if let m = try await RemoteEdgeClient().reconstruct(from: bundle) as FaceMesh3D? { return m } } catch { DebugLog.log("remote_edge_error: \(error.localizedDescription)") }
            if let m = await reconstruct(backend: .decaEdge) { return m }
            if let m = await reconstruct(backend: .threeDDFA) { return m }
            // Show UI banner upstream if needed
            return await reconstruct(backend: .arkit)
        } else {
            if let m = await reconstruct(backend: .arkit) { return m }
            if let m = await reconstruct(backend: .decaEdge) { return m }
            return await reconstruct(backend: .threeDDFA)
        }
    }
}


