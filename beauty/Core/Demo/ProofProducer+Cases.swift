import Foundation
import UIKit

extension ProofProducer {
    /// Produce a simple screenshot for CaseSearch list (static rendering for Proof/CI)
    static func produceCaseSearchShots() -> URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let out = docs.appendingPathComponent("proof/cases", isDirectory: true)
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        let img = CaseSearchShotRenderer.render()
        _ = try? img.pngData()?.write(to: out.appendingPathComponent("cases.png"))
        return out
    }
}

enum CaseSearchShotRenderer {
    static func render() -> UIImage {
        let size = CGSize(width: 800, height: 480)
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { ctx in
            UIColor.white.setFill(); ctx.fill(CGRect(origin: .zero, size: size))
            let title = "相似案例（示意截图）" as NSString
            title.draw(at: CGPoint(x: 16, y: 12), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18)])
            let items = [
                ("隆鼻 + 鼻尖上旋", 6, 0.82),
                ("颏成形（填充）", 3, 0.79)
            ]
            for (idx, it) in items.enumerated() {
                let y = 60 + idx*96
                UIColor.systemGray5.setFill(); ctx.fill(CGRect(x: 16, y: y, width: 64, height: 64))
                let proc = it.0 as NSString
                proc.draw(at: CGPoint(x: 96, y: y+10), withAttributes: [.font: UIFont.systemFont(ofSize: 16)])
                let sub = String(format: "术后 %d 个月 • 相似度 %.2f", it.1, it.2) as NSString
                sub.draw(at: CGPoint(x: 96, y: y+36), withAttributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.gray])
            }
        }
    }
}


