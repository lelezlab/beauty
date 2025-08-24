import AVFoundation
import CoreImage

struct QualityScore { let blur: Double; let exposure: Double; let occlusion: Double; let coverage: Double }

enum CaptureQuality {
    static func score(sample: CMSampleBuffer) -> QualityScore {
        guard let pixel = CMSampleBufferGetImageBuffer(sample) else { return .init(blur: 0.5, exposure: 0.5, occlusion: 0.0, coverage: 0.3) }
        let ci = CIImage(cvPixelBuffer: pixel)
        let extent = ci.extent
        let ctx = CIContext(options: nil)
        // Exposure proxy: luminance via CIAreaAverage
        let avg = CIFilter(name: "CIAreaAverage")!
        avg.setValue(ci, forKey: kCIInputImageKey)
        avg.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
        var exposure: Double = 0.6
        if let out = avg.outputImage, let cg = ctx.createCGImage(out, from: CGRect(x: 0, y: 0, width: 1, height: 1)) {
            let data = CFDataCreateMutable(nil, 0)
            let dest = CGImageDestinationCreateWithData(data!, UTType.png.identifier as CFString, 1, nil)
            if let dest = dest { CGImageDestinationAddImage(dest, cg, nil); CGImageDestinationFinalize(dest) }
            if let bytes = CFDataGetBytePtr(data!) { let r = Double(bytes[33])/255.0; let g = Double(bytes[34])/255.0; let b = Double(bytes[35])/255.0; exposure = 0.2126*r + 0.7152*g + 0.0722*b }
        }
        // Blur proxy: CIEdges strength average
        var blur: Double = 0.5
        let edges = CIFilter(name: "CIEdges")!; edges.setValue(ci, forKey: kCIInputImageKey); edges.setValue(1.0, forKey: kCIInputIntensityKey)
        if let eout = edges.outputImage {
            let a = CIFilter(name: "CIAreaAverage")!; a.setValue(eout, forKey: kCIInputImageKey); a.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
            if let out = a.outputImage, let cg = ctx.createCGImage(out, from: CGRect(x: 0, y: 0, width: 1, height: 1)) {
                let data = CFDataCreateMutable(nil, 0); let dest = CGImageDestinationCreateWithData(data!, UTType.png.identifier as CFString, 1, nil); if let dest = dest { CGImageDestinationAddImage(dest, cg, nil); CGImageDestinationFinalize(dest) }
                if let bytes = CFDataGetBytePtr(data!) { let r = Double(bytes[33])/255.0; let g = Double(bytes[34])/255.0; let b = Double(bytes[35])/255.0; blur = (r+g+b)/3.0 }
            }
        }
        // TODO: occlusion/coverage via Vision face rect（占位返回）
        return .init(blur: blur, exposure: exposure, occlusion: 0.0, coverage: 0.3)
    }
}


