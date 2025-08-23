import Foundation
import UIKit

enum TriViewSampleProvider {
    static func reconstructMesh() async throws -> FaceMesh3D {
        // Load samples from bundle; if missing, throw
        guard let f = Bundle.main.url(forResource: "ProofSamples/tri_front", withExtension: "jpg"),
              let l = Bundle.main.url(forResource: "ProofSamples/tri_left", withExtension: "jpg"),
              let r = Bundle.main.url(forResource: "ProofSamples/tri_right", withExtension: "jpg") else {
            throw NSError(domain: "Proof", code: -20, userInfo: [NSLocalizedDescriptionKey: "Sample tri-view images not found"])
        }
        let front = UIImage(contentsOfFile: f.path)
        let left = UIImage(contentsOfFile: l.path)
        let right = UIImage(contentsOfFile: r.path)
        var b = ReconstructionOrchestrator.shared.buildBundleFromCapture()
        b.front = front; b.left = left; b.right = right
        do {
            if let mesh = try await EdgeReconstruction().reconstruct(from: b) as FaceMesh3D? { return mesh }
        } catch { /* fallthrough to mock */ }
        // Fallback to a trivial mesh to keep pipeline running in demo
        return try await MockTrueDepthProvider.loadMesh()
    }
}


