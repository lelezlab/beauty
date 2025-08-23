import Foundation
import SwiftUI

enum ProofMode { case mockTrueDepth, triViewEdgePlaceholder }

struct ProofProducer {
    static func run(mode: ProofMode) async throws -> URL {
        let dir = try prepareDir(mode: mode)
        let mesh: FaceMesh3D = try await makeMesh(mode: mode)
        // Record scene
        let videoURL = dir.appendingPathComponent("demo.mp4")
        try await SceneRecorder.record(mesh: mesh, duration: 12, output: videoURL)
        // Diagnostics snapshot
        let diag = DiagnosticsSnapshotter.snapshot(mode: mode)
        let diagURL = dir.appendingPathComponent("diagnostics.png")
        try diag.pngData()?.write(to: diagURL)
        return dir
    }

    private static func makeMesh(mode: ProofMode) async throws -> FaceMesh3D {
        switch mode {
        case .mockTrueDepth:
            return try await MockTrueDepthProvider.loadMesh()
        case .triViewEdgePlaceholder:
            return try await TriViewSampleProvider.reconstructMesh()
        }
    }

    private static func prepareDir(mode: ProofMode) throws -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("proof", isDirectory: true)
        let dir = base.appendingPathComponent(mode == .mockTrueDepth ? "mockTrueDepth" : "triView", isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}


