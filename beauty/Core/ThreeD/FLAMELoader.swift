import Foundation
import simd

public struct FLAMEAssets { public let vTemplate: [SIMD3<Float>]; public let faces: [SIMD3<UInt32>]; public let shapeBasis: [[SIMD3<Float>]]; public let exprBasis: [[SIMD3<Float>]] }

public enum FLAMELoader {
    public static func load(from url: URL) throws -> FLAMEAssets {
        // Placeholder: throw to trigger fallback; real loader to be implemented for .npz/.json
        throw NSError(domain: "FLAME", code: -1, userInfo: [NSLocalizedDescriptionKey: "FLAME unavailable, falling back to ARKit/PCA"])
    }
}


