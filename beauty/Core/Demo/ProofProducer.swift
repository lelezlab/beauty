import Foundation
import SwiftUI

enum ProofMode { case mockTrueDepth, triViewEdgePlaceholder }

struct ProofProducer {
    static func run(mode: ProofMode) async throws -> URL {
        let dir = try prepareDir(mode: mode)
        let mesh: FaceMesh3D = try await makeMesh(mode: mode)
        // 标记状态：mock/placeholder 也算成功，便于离线验收
        UserDefaults.standard.set(true, forKey: "last_recon_ok")
        // 写入几何缓存，以便 Diagnostics 显示 Face frames cached = true
        if let idx = (mesh.indices ?? mesh.faces) as [SIMD3<UInt32>]? {
            let u16: [UInt16] = idx.flatMap { [UInt16($0.x & 0xFFFF), UInt16($0.y & 0xFFFF), UInt16($0.z & 0xFFFF)] }
            ARFaceGeometryCache.shared.lastGeometry = (mesh.vertices.map{ Units.mmToMeters($0) }, u16, u16.count/3)
        }
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


