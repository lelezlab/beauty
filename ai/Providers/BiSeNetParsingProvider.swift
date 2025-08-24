import Foundation
import CoreVideo

final class BiSeNetParsingProvider: FaceParsingProvider {
    let name = "bisenet_face_parsing"
    private(set) var isReady = false
    private(set) var modelBytes: Int64?
    private(set) var loadLatencyMS: Int?

    func warmup() throws {
        let t0 = Date()
        let path = try ModelRegistry.path(for: ModelIDs.bisenetONNX)
        let attr = try FileManager.default.attributesOfItem(atPath: path)
        self.modelBytes = (attr[.size] as? NSNumber)?.int64Value
        let be = InferenceBackend(type: .none)
        try? be.load(modelPath: path)
        self.isReady = true
        self.loadLatencyMS = Int(Date().timeIntervalSince(t0) * 1000)
    }

    func parse(in pixelBuffer: CVPixelBuffer) throws -> (labels: [UInt8], width: Int, height: Int) {
        guard isReady else { throw AIErrors.notReady("bisenet") }
        let t0 = Date()
        // M1 MVP: produce a simple skin/non-skin mask using Vision face bounds as proxy
        let w = CVPixelBufferGetWidth(pixelBuffer)
        let h = CVPixelBufferGetHeight(pixelBuffer)
        var labels = Array<UInt8>(repeating: 0, count: w*h)
        autoreleasepool {
            let ci = CIImage(cvPixelBuffer: pixelBuffer)
            let ctx = CIContext(); if let cg = ctx.createCGImage(ci, from: ci.extent) {
                let ui = UIImage(cgImage: cg)
                let req = VNDetectFaceRectanglesRequest()
                let handler = VNImageRequestHandler(cgImage: cg, orientation: VisionLandmarksHelper.cgOrientation(of: ui), options: [:])
                try? handler.perform([req])
                if let face = req.results?.first as? VNFaceObservation {
                    let r = face.boundingBox
                    // Fill face bbox as label 1 (non-zero), others 0
                    for y in 0..<h {
                        for x in 0..<w {
                            let nx = Double(x)/Double(w)
                            let ny = Double(y)/Double(h)
                            if nx >= r.origin.x, nx <= r.origin.x + r.size.width, ny >= r.origin.y, ny <= r.origin.y + r.size.height {
                                labels[y*w + x] = 1
                            }
                        }
                    }
                }
            }
        }
        LatencyTracker.addSample(Date().timeIntervalSince(t0)*1000.0, key: "parsing_ms")
        return (labels, w, h)
    }
}


