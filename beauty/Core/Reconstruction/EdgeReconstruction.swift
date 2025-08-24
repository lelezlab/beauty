import Foundation
import UIKit

final class EdgeReconstruction: ReconstructionProvider {
    enum EdgeError: LocalizedError {
        case notConfigured
        case placeholderEnabled
        case unreachable
        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Edge reconstruction URL not configured. Set Info.plist key 'EdgeReconURL' or enable placeholder."
            case .placeholderEnabled:
                return "Using placeholder Edge (debug). Disable 'Use Placeholder Edge' to call real endpoint."
            case .unreachable:
                return "Edge reconstruction unavailable in demo build."
            }
        }
    }

    func reconstruct(from bundle: CaptureBundle) async throws -> FaceMesh3D {
        // Auto-switch: prefer remote if configured; otherwise use mock provider
        if let urlStr = Bundle.main.object(forInfoDictionaryKey: "EdgeReconURL") as? String,
           let url = URL(string: urlStr), !urlStr.isEmpty, !AppDebugFlags.usePlaceholderEdge {
            // Remote path
            let mesh = try await RemoteEdgeProvider.reconstructTriView(bundle: bundle, endpoint: url)
            UserDefaults.standard.set("remote", forKey: "edge_provider")
            UserDefaults.standard.set(true, forKey: "edge_last_ok")
            return mesh
        } else {
            // Mock path (zero-interaction demo)
            let mesh = try await MockEdgeProvider.reconstructDemo(bundle: bundle)
            UserDefaults.standard.set("mock", forKey: "edge_provider")
            UserDefaults.standard.set(true, forKey: "edge_last_ok")
            return mesh
        }
    }
}


