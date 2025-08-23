import Foundation
import UIKit

enum TriViewSampleProvider {
    static func reconstructMesh() async throws -> FaceMesh3D {
        // Load samples from bundle; if missing, synthesize simple placeholders
        let f = Bundle.main.url(forResource: "ProofSamples/tri_front", withExtension: "jpg")
        let l = Bundle.main.url(forResource: "ProofSamples/tri_left", withExtension: "jpg")
        let r = Bundle.main.url(forResource: "ProofSamples/tri_right", withExtension: "jpg")
        let front = f.flatMap { UIImage(contentsOfFile: $0.path) } ?? synthesize(label: "FRONT", color: .systemTeal)
        let left  = l.flatMap { UIImage(contentsOfFile: $0.path) } ?? synthesize(label: "LEFT", color: .systemBlue)
        let right = r.flatMap { UIImage(contentsOfFile: $0.path) } ?? synthesize(label: "RIGHT", color: .systemGreen)
        var b = ReconstructionOrchestrator.shared.buildBundleFromCapture()
        b.front = front; b.left = left; b.right = right
        do {
            if let mesh = try await EdgeReconstruction().reconstruct(from: b) as FaceMesh3D? { return mesh }
        } catch { /* fallthrough to mock */ }
        // Fallback to a trivial mesh to keep pipeline running in demo
        return try await MockTrueDepthProvider.loadMesh()
    }

    private static func synthesize(label: String, color: UIColor) -> UIImage {
        let size = CGSize(width: 720, height: 960)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill(); ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 64),
                .foregroundColor: UIColor.white
            ]
            let text = label as NSString
            let p = CGPoint(x: 40, y: size.height/2 - 32)
            text.draw(at: p, withAttributes: attrs)
        }
    }
}


