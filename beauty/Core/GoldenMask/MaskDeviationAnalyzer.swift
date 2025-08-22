import Foundation
import CoreGraphics

/// 计算与黄金面罩关键锚点的偏差（毫米）。
/// 先以眼距(IPD)归一化，再用 CalibrationManager.scaleMMPerPixel 转回 mm；若无标定则返回像素近似（按 1px≈1mm 升级占位）。
enum MaskDeviationAnalyzer {
    struct DeviationPoint: Identifiable { let id: String; let point: CGPoint; let deltaMM: Double }

    static func analyze2D(landmarks: FacialLandmarksResult?, imageSize: CGSize) -> [DeviationPoint] {
        guard let lm = landmarks, !lm.points.isEmpty else { return [] }
        // 选择一组锚点（示意）：鼻尖(鼻部中线最低点近似)、两眶中心、颏点（下唇外侧最低近似）
        let chosen: [(id: String, key: String, indexHint: Int?)] = [
            ("nasion", "noseCrest", 0),
            ("pronasale", "nose", nil),
            ("pogonion", "faceContour", nil)
        ]
        // 估计 IPD（归一化距离）
        guard let le = lm.points["leftEye"], let re = lm.points["rightEye"], !le.isEmpty, !re.isEmpty else { return [] }
        let lc = avg(le), rc = avg(re)
        let ipdPx = hypot(Double(lc.x - rc.x), Double(lc.y - rc.y))
        let mmPerPx = CalibrationManager.shared.state.scaleMMPerPixel ?? 1.0
        var out: [DeviationPoint] = []
        for item in chosen {
            guard let arr = lm.points[item.key], !arr.isEmpty else { continue }
            let p: CGPoint = {
                if let idx = item.indexHint, arr.indices.contains(idx) { return arr[idx] }
                return avg(arr)
            }()
            // 构建一个极简黄金参考：眼间中点到鼻尖垂线、颏点在面下三分之一（示意占位）
            let mid = CGPoint(x: (lc.x+rc.x)/2.0, y: (lc.y+rc.y)/2.0)
            let goldenYForId: CGFloat = {
                switch item.id {
                case "nasion": return mid.y - CGFloat(0.25)*CGFloat(ipdPx) // 眉间略高于眼中点
                case "pronasale": return mid.y + CGFloat(0.6)*CGFloat(ipdPx)
                case "pogonion": return mid.y + CGFloat(2.2)*CGFloat(ipdPx)
                default: return p.y
                }
            }()
            let ref = CGPoint(x: mid.x, y: goldenYForId)
            let dPx = hypot(Double(p.x - ref.x), Double(p.y - ref.y))
            let dMM = dPx * Double(mmPerPx)
            out.append(DeviationPoint(id: item.id, point: p, deltaMM: dMM))
        }
        return out
    }

    private static func avg(_ pts: [CGPoint]) -> CGPoint {
        guard !pts.isEmpty else { return .zero }
        let sx = pts.map{$0.x}.reduce(0, +)
        let sy = pts.map{$0.y}.reduce(0, +)
        return CGPoint(x: sx/CGFloat(pts.count), y: sy/CGFloat(pts.count))
    }
}


