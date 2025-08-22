import UIKit
import PDFKit

enum ExportService {
    enum Layout { case vertical, horizontal }
    static func compositeBeforeAfter(before: UIImage, after: UIImage, watermark: String, layout: Layout = .vertical, showAB: Bool = true, regionText: String? = nil, timestamp: Date = Date()) -> UIImage? {
        let padding: CGFloat = 20
        let labelHeight: CGFloat = 20
        let attrsAB: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14, weight: .semibold), .foregroundColor: UIColor.darkGray]
        var canvas: CGSize
        switch layout {
        case .vertical:
            let width = max(before.size.width, after.size.width)
            let height = before.size.height + after.size.height + padding*2 + labelHeight
            canvas = CGSize(width: width, height: height)
            UIGraphicsBeginImageContextWithOptions(canvas, true, 0)
            UIColor.white.setFill(); UIRectFill(CGRect(origin: .zero, size: canvas))
            before.draw(in: CGRect(x: 0, y: 0, width: width, height: before.size.height))
            if showAB { ("A" as NSString).draw(at: CGPoint(x: 6, y: 6), withAttributes: attrsAB) }
            after.draw(in: CGRect(x: 0, y: before.size.height + padding, width: width, height: after.size.height))
            if showAB { ("B" as NSString).draw(at: CGPoint(x: 6, y: before.size.height + padding + 6), withAttributes: attrsAB) }
        case .horizontal:
            let height = max(before.size.height, after.size.height)
            let width = before.size.width + after.size.width + padding
            canvas = CGSize(width: width, height: height + labelHeight)
            UIGraphicsBeginImageContextWithOptions(canvas, true, 0)
            UIColor.white.setFill(); UIRectFill(CGRect(origin: .zero, size: canvas))
            before.draw(in: CGRect(x: 0, y: 0, width: before.size.width, height: height))
            if showAB { ("A" as NSString).draw(at: CGPoint(x: 6, y: 6), withAttributes: attrsAB) }
            after.draw(in: CGRect(x: before.size.width + padding, y: 0, width: after.size.width, height: height))
            if showAB { ("B" as NSString).draw(at: CGPoint(x: before.size.width + padding + 6, y: 6), withAttributes: attrsAB) }
        }
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
        let region = regionText ?? ""
        let dateStr = DateFormatter.localizedString(from: timestamp, dateStyle: .short, timeStyle: .short)
        let meta = ([watermark, dateStr, region] + metaParts).filter{ !$0.isEmpty }.joined(separator: "  ")
        let str = NSAttributedString(string: meta, attributes: attrs)
        str.draw(at: CGPoint(x: 10, y: canvas.height - 20))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }

    static func makePDF(from image: UIImage, disclaimer: String, procedure: Procedure? = nil, metrics: BTMetricsPayload? = nil, location: String? = nil, timestamp: Date = Date(), bddScore: Int? = nil, consistency: Double? = nil) -> Data? {
        let pdfMetaData = [kCGPDFContextCreator: "beauty App"]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        // 预留摘要表与声明空间
        let extraHeight: CGFloat = 200
        let pageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height + extraHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor.black
            ]
            let valueAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            let yStart = image.size.height + 10
            let leftX: CGFloat = 12
            let colGap: CGFloat = 8
            let col1W: CGFloat = max(120, pageRect.width * 0.28)
            let col2W: CGFloat = pageRect.width - leftX*2 - col1W

            // 表格行构造
            var rows: [(String, String)] = []
            if let p = procedure {
                let budgetMin = p.budgetUSD.first ?? 0
                let budgetMax = p.budgetUSD.last ?? 0
                rows.append(("选中术式", p.name))
                rows.append(("预算区间", "$\(budgetMin) - $\(budgetMax)"))
                rows.append(("恢复期(估)", "~\(p.recoveryDays)d"))
                if let bn = p.budgetNotes, !bn.isEmpty { rows.append(("预算提示", bn.joined(separator: "；"))) }
                if let q = p.questionChecklist, !q.isEmpty { rows.append(("问题清单", q.prefix(4).joined(separator: "；"))) }
                if let c = p.contraindications, !c.isEmpty { rows.append(("禁忌摘要", c.prefix(3).joined(separator: "；"))) }
                if let a = p.aftercare, !a.isEmpty { rows.append(("术后护理", a.prefix(3).joined(separator: "；"))) }
            }
            if let m = metrics {
                var metricStrs: [String] = []
                if let v = m.threeZones { metricStrs.append(String(format: "三庭: %.2f", v)) }
                if let v = m.fiveEyes { metricStrs.append(String(format: "五眼: %.2f", v)) }
                if let v = m.nasolabialDeg { metricStrs.append(String(format: "鼻唇角: %.0f°", v)) }
                if let v = m.chinProjection { metricStrs.append(String(format: "下巴投影: %.2f", v)) }
                if let v = m.faceWH { metricStrs.append(String(format: "宽高比: %.2f", v)) }
                if !metricStrs.isEmpty { rows.append(("关键指标", metricStrs.joined(separator: "  |  "))) }
                if let c = m.confidence { rows.append(("可信度", String(format: "%.0f%%", c*100))) }
            }
            if let cons = consistency { rows.append(("三视图一致性", String(format: "%.0f%%", cons*100))) }
            let timeStr = DateFormatter.localizedString(from: timestamp, dateStyle: .medium, timeStyle: .short)
            if let loc = location, !loc.isEmpty { rows.append(("时间/地点", "\(timeStr)  @ \(loc)")) }
            else { rows.append(("时间", timeStr)) }

            // 如果有 BDD 分数，加入摘要
            if let s = bddScore {
                let risk: String = (s <= 3) ? "低风险" : ((s <= 6) ? "中等关注" : "建议进一步评估")
                rows.append(("BDD 自评", "总分 \(s)（\(risk)）"))
            }

            // 绘制表格
            var y = yStart
            let rowH: CGFloat = 20
            for (k, v) in rows {
                // key cell
                (k as NSString).draw(in: CGRect(x: leftX, y: y, width: col1W, height: rowH), withAttributes: titleAttrs)
                // value cell
                (v as NSString).draw(in: CGRect(x: leftX + col1W + colGap, y: y, width: col2W - colGap, height: rowH), withAttributes: valueAttrs)
                y += rowH + 6
            }

            // 免责声明
            let disclaimerRect = CGRect(x: leftX, y: y + 4, width: pageRect.width - leftX*2, height: max(60, pageRect.height - (y + 8)))
            (disclaimer as NSString).draw(in: disclaimerRect, withAttributes: valueAttrs)
        }
        return data
    }
}


