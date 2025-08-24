import Foundation
import UIKit

enum TriViewSampleProvider {
    static func reconstructMesh() async throws -> FaceMesh3D {
        // Load samples: Bundle first, then Documents/proof_samples, finally synthesize
        let bundleFront = Bundle.main.url(forResource: "ProofSamples/tri_front", withExtension: "jpg")
        let bundleLeft  = Bundle.main.url(forResource: "ProofSamples/tri_left", withExtension: "jpg")
        let bundleRight = Bundle.main.url(forResource: "ProofSamples/tri_right", withExtension: "jpg")
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("proof_samples", isDirectory: true)
        let docFront = docs.appendingPathComponent("tri_front.jpg")
        let docLeft  = docs.appendingPathComponent("tri_left.jpg")
        let docRight = docs.appendingPathComponent("tri_right.jpg")
        let front = (bundleFront ?? (FileManager.default.fileExists(atPath: docFront.path) ? docFront : nil)).flatMap { UIImage(contentsOfFile: $0.path) } ?? synthesize(label: "FRONT", color: .systemTeal)
        let left  = (bundleLeft  ?? (FileManager.default.fileExists(atPath: docLeft.path)  ? docLeft  : nil)).flatMap { UIImage(contentsOfFile: $0.path) } ?? synthesize(label: "LEFT", color: .systemBlue)
        let right = (bundleRight ?? (FileManager.default.fileExists(atPath: docRight.path) ? docRight : nil)).flatMap { UIImage(contentsOfFile: $0.path) } ?? synthesize(label: "RIGHT", color: .systemGreen)
        var b = ReconstructionOrchestrator.shared.buildBundleFromCapture()
        b.front = front; b.left = left; b.right = right
        do {
            if let mesh = try await EdgeReconstruction().reconstruct(from: b) as FaceMesh3D? { return mesh }
        } catch {
            // mark message hint for UI toast
            print("triView_error: \(error.localizedDescription)")
        }
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


