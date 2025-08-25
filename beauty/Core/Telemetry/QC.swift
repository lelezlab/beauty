import Foundation
import CoreImage

enum QC {
    static func blurScore(_ image: CIImage) -> Double {
        let kernel = CIFilter(name: "Laplacian") ?? CIFilter(name: "CILaplacian")
        kernel?.setValue(image, forKey: kCIInputImageKey)
        guard let out = kernel?.outputImage else { return 0.0 }
        let extent = out.extent
        let ctx = CIContext()
        guard let data = ctx.createCGImage(out, from: extent) else { return 0.0 }
        let mean = imageMeanLuma(data)
        return min(max(mean / 128.0, 0.0), 1.0)
    }

    static func exposureMean(_ image: CIImage) -> Double {
        let extent = image.extent
        let ctx = CIContext()
        guard let cg = ctx.createCGImage(image, from: extent) else { return 0.5 }
        return imageMeanLuma(cg)
    }

    static func coverage(faceBox: CGRect, frame: CGRect) -> Double {
        let area = faceBox.width * faceBox.height
        let total = frame.width * frame.height
        guard total > 0 else { return 0 }
        return min(max(Double(area/total), 0), 1)
    }

    private static func imageMeanLuma(_ cg: CGImage) -> Double {
        guard let data = cg.dataProvider?.data as Data? else { return 0.5 }
        let bytes = [UInt8](data)
        var sum = 0.0
        let step = max(1, bytes.count/4096)
        for i in stride(from: 0, to: bytes.count, by: step) { sum += Double(bytes[i]) }
        return sum / Double(bytes.count/step) / 255.0
    }
}


