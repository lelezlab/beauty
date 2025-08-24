import Foundation
import CoreGraphics

extension ProofProducer {
    /// Convenience: generate AI metrics, mirror export and case search shots in one tap.
    static func produceAllProofExtras() {
        // AI metrics
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let aiOut = docs.appendingPathComponent("proof/ai_metrics", isDirectory: true)
        try? FileManager.default.createDirectory(at: aiOut, withIntermediateDirectories: true)
        AppFlags.isProofRunning = true
        autoreleasepool {
            ProofProducer().produceAIMetricsProof(mesh: CaptureStore.shared.lastMesh, landmarks: nil, outDir: aiOut)
        }
        AppFlags.isProofRunning = false
        // Mirror
        _ = ProofProducer.produceMirrorDemo()
        // Cases
        _ = ProofProducer.produceCaseSearchShots()
    }
}


