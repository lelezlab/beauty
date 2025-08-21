import UIKit
import PDFKit

enum ExportService {
    static func compositeBeforeAfter(before: UIImage, after: UIImage, watermark: String) -> UIImage? {
        let width = max(before.size.width, after.size.width)
        let height = before.size.height + after.size.height + 40
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), true, 0)
        UIColor.white.setFill(); UIRectFill(CGRect(x: 0, y: 0, width: width, height: height))
        before.draw(in: CGRect(x: 0, y: 0, width: width, height: before.size.height))
        after.draw(in: CGRect(x: 0, y: before.size.height + 20, width: width, height: after.size.height))
        // watermark
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: UIColor.gray.withAlphaComponent(0.7)
        ]
        let qc = BeautyTelemetryService.shared.lastQC
        let metaParts: [String] = [
            qc?.focalEq.map { String(format: "f=%.0fmm", $0) } ?? "f≈50mm",
            qc?.distanceBucket.map { "d\($0)" } ?? "d?",
            qc?.yaw.map { String(format: "yaw=%.0f°", $0) } ?? "yaw?",
            qc?.pitch.map { String(format: "pitch=%.0f°", $0) } ?? "pitch?",
            qc?.roll.map { String(format: "roll=%.0f°", $0) } ?? "roll?",
            (qc?.aeLocked ?? false) ? "AE:lock" : "AE:auto",
            (qc?.awbLocked ?? false) ? "AWB:lock" : "AWB:auto"
        ]
        let meta = metaParts.joined(separator: "  ")
        let str = NSAttributedString(string: watermark + "  " + meta, attributes: attrs)
        str.draw(at: CGPoint(x: 10, y: height - 20))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }

    static func makePDF(from image: UIImage, disclaimer: String) -> Data? {
        let pdfMetaData = [kCGPDFContextCreator: "beauty App"]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        let pageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height + 120)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            disclaimer.draw(in: CGRect(x: 12, y: image.size.height + 12, width: image.size.width - 24, height: 100), withAttributes: attrs)
        }
        return data
    }
}


