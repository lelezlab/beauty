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
        let str = NSAttributedString(string: watermark, attributes: attrs)
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


