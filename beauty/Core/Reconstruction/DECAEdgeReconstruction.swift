import Foundation
import UIKit
import simd

public final class DECAEdgeReconstruction: ReconstructionProvider {
    public init() {}
    public func reconstruct(from bundle: CaptureBundle) async throws -> FaceMesh3D {
        // Edge 函数占位：若未配置，返回 ARKit 占位网格
        let fallback = ARKitReconstruction()
        return try await fallback.reconstruct(from: bundle)
    }
}


