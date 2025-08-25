import Foundation
import CoreVideo
import CoreGraphics

@MainActor
public final class AIOrchestrator {
    public static let shared = AIOrchestrator()

    private(set) var landmarks: FaceLandmarksProvider = MediaPipeFaceLandmarksProvider()
    private(set) var parsing:   FaceParsingProvider    = BiSeNetParsingProvider()
    private(set) var depth:     DepthProvider          = MiDaSDepthProvider()
    private(set) var embedder:  FaceEmbedProvider      = InsightFaceEmbedProvider()
    private(set) var recon3D:   Face3DProvider         = DECAFace3DProvider()

    public var providers: [AIModelProvider] {
        [landmarks, parsing, depth, embedder, recon3D]
    }

    private init() {}

    public func warmupAll() async {
        for p in providers {
            do { try p.warmup() } catch {
                DebugLog.log("AI warmup failed \(p.name): \(error.localizedDescription)")
            }
        }
    }

    public func detectLandmarks(in pb: CVPixelBuffer) throws -> [CGPoint] {
        guard landmarks.isReady else { throw AIErrors.notReady("landmarks") }
        return try landmarks.detect(in: pb)
    }

    public func parseFace(in pb: CVPixelBuffer) throws -> (labels:[UInt8], w:Int, h:Int) {
        guard parsing.isReady else { throw AIErrors.notReady("parsing") }
        let r = try parsing.parse(in: pb)
        return (r.labels, r.width, r.height)
    }

    public func estimateDepth(in pb: CVPixelBuffer) throws -> (depth:[Float], w:Int, h:Int) {
        guard depth.isReady else { throw AIErrors.notReady("depth") }
        let r = try depth.depth(in: pb)
        return (r.depth, r.width, r.height)
    }

    public func embed(in pb: CVPixelBuffer) throws -> [Float] {
        guard embedder.isReady else { throw AIErrors.notReady("embedder") }
        return try embedder.embed(in: pb)
    }

    public func reconstruct3D(triViews: [CGImage]) throws -> FaceMesh3D {
        guard recon3D.isReady else { throw AIErrors.notReady("recon3D") }
        return try recon3D.reconstruct(triViews: triViews)
    }
}


