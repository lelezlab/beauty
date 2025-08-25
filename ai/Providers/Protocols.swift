import Foundation
import CoreVideo
import CoreGraphics

public protocol AIModelProvider {
    var name: String { get }
    func warmup() throws
    var isReady: Bool { get }
    var modelBytes: Int64? { get }  // for diagnostics
    var loadLatencyMS: Int? { get }
}

public protocol FaceLandmarksProvider: AIModelProvider {
    /// Return 468/478 points in image coordinates (normalized 0~1).
    func detect(in pixelBuffer: CVPixelBuffer) throws -> [CGPoint]
}

public protocol Face3DProvider: AIModelProvider {
    func reconstruct(triViews: [CGImage]) throws -> FaceMesh3D
}

public protocol FaceParsingProvider: AIModelProvider {
    /// Return label map width x height (UInt8 label id).
    func parse(in pixelBuffer: CVPixelBuffer) throws -> (labels: [UInt8], width: Int, height: Int)
}

public protocol DepthProvider: AIModelProvider {
    /// Return per-pixel depth (meters) aligned to input.
    func depth(in pixelBuffer: CVPixelBuffer) throws -> (depth: [Float], width: Int, height: Int)
}

public protocol FaceEmbedProvider: AIModelProvider {
    /// 512-D embedding for similar-case retrieval (NOT for identification).
    func embed(in pixelBuffer: CVPixelBuffer) throws -> [Float]
}


