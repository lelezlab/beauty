import SwiftUI

struct GoldenGuidesOverlay: View {
    var landmarks: FacialLandmarksResult? = nil
    var config: GoldenMaskConfig = .fromDefaults()
    var metrics: AestheticsMetrics? = nil
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Canvas { ctx, _ in
                let w = size.width
                let h = size.height
                let stroke = StrokeStyle(lineWidth: 1, dash: [5,5])
                // 五眼（垂直分割线，共 6 条）
                let ipd = inferredIPD(from: landmarks, in: size) // 以瞳距估计，缺省退回宽度比例
                let span = max(ipd * config.eyeWidthRatio, 24)
                let leftX = (w - span*5)/2
                for i in 0...5 {
                    var p = Path()
                    let x = leftX + CGFloat(i)*span
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: h))
                    ctx.stroke(p, with: .color(.yellow.opacity(0.5)), style: stroke)
                }
                // 三庭（水平 2 条线）
                for i in 1...2 {
                    var p = Path()
                    let y = h*CGFloat(i)/3
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: w, y: y))
                    ctx.stroke(p, with: .color(.yellow.opacity(0.5)), style: stroke)
                }
                // 椭圆轮廓参考
                let rect = CGRect(x: w*config.faceRect.origin.x, y: h*config.faceRect.origin.y, width: w*config.faceRect.size.width, height: h*config.faceRect.size.height)
                ctx.stroke(Path(ellipseIn: rect), with: .color(.yellow.opacity(0.35)), lineWidth: 1)

                // 关键差异标签（若有指标）
                if let m = metrics {
                    let lines: [String] = {
                        let tz = String(format: "三庭 %.2f → 1.00", m.threeFacialZonesRatio)
                        let fe = String(format: "五眼 %.2f → 1.00", m.fiveEyesRatio)
                        let na = String(format: "鼻唇角 %.1f° → 103°", m.nasolabialAngleDegrees)
                        let cp = String(format: "下巴投影 %.2f → 1.00", m.chinProjectionRatio)
                        let wh = String(format: "宽高比 %.2f → 0.75", m.faceWidthToHeight)
                        return [tz, fe, na, cp, wh]
                    }()
                    var y: CGFloat = 10
                    // 计算“还差多少”的简化提示
                    let assumedIPDmm = UserDefaults.standard.object(forKey: "gm_ipd_mm") as? Double ?? 63.0
                    let mmPerPx = ipd > 0 ? CGFloat(assumedIPDmm) / ipd : 0
                    let chinPct = max(0.0, 1.0 - m.chinProjectionRatio)
                    let fivePct = max(0.0, 1.0 - m.fiveEyesRatio)
                    let chinPx = CGFloat(chinPct) * ipd
                    let fivePx = CGFloat(fivePct) * ipd
                    let chinMm = chinPx * mmPerPx
                    let fiveMm = fivePx * mmPerPx
                    let deltas: [String] = [
                        String(format: "下巴 +%.0f%% (≈%.1fmm/%.0fpx)", chinPct*100, chinMm, chinPx),
                        String(format: "五眼 +%.0f%% (≈%.1fmm/%.0fpx)", fivePct*100, fiveMm, fivePx)
                    ]
                    for s in lines {
                        let t = Text(s).font(.system(size: 10, weight: .semibold, design: .monospaced)).foregroundColor(.yellow)
                        ctx.draw(t, at: CGPoint(x: 10, y: y), anchor: .topLeading)
                        y += 14
                    }
                    // 右侧以橙色提示 delta，并画小箭头标尺（示意）
                    var yRight: CGFloat = 10
                    for (idx, s) in deltas.enumerated() {
                        let t = Text(s).font(.system(size: 10, weight: .regular, design: .monospaced)).foregroundColor(.orange)
                        ctx.draw(t, at: CGPoint(x: w - 150, y: yRight), anchor: .topLeading)
                        // 画一条与像素成比例的水平箭头（上方：五眼，下方：下巴）
                        let lengthPx: CGFloat = idx == 0 ? chinPx : fivePx
                        let baseY = yRight + 12
                        let x0 = w - 150
                        let x1 = min(w - 10, x0 + max(20, lengthPx * 0.15))
                        var path = Path()
                        path.move(to: CGPoint(x: x0, y: baseY))
                        path.addLine(to: CGPoint(x: x1, y: baseY))
                        // 箭头
                        path.move(to: CGPoint(x: x1-6, y: baseY-3))
                        path.addLine(to: CGPoint(x: x1, y: baseY))
                        path.addLine(to: CGPoint(x: x1-6, y: baseY+3))
                        ctx.stroke(path, with: .color(.orange), lineWidth: 1)
                        yRight += 20
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct GoldenMaskConfig {
    var eyeWidthRatio: CGFloat = 0.14 // eye span 基于 IPD 的比例
    var faceRect: CGRect = CGRect(x: 0.15, y: 0.1, width: 0.7, height: 0.85)
    static let `default` = GoldenMaskConfig()
    static func fromDefaults() -> GoldenMaskConfig {
        var c = GoldenMaskConfig()
        if let v = UserDefaults.standard.object(forKey: "gm_eyeWidthRatio") as? Double { c.eyeWidthRatio = CGFloat(v) }
        let x = UserDefaults.standard.object(forKey: "gm_faceRectX") as? Double ?? 0.15
        let y = UserDefaults.standard.object(forKey: "gm_faceRectY") as? Double ?? 0.10
        let w = UserDefaults.standard.object(forKey: "gm_faceRectW") as? Double ?? 0.70
        let h = UserDefaults.standard.object(forKey: "gm_faceRectH") as? Double ?? 0.85
        c.faceRect = CGRect(x: x, y: y, width: w, height: h)
        return c
    }
}

private func inferredIPD(from lmk: FacialLandmarksResult?, in size: CGSize) -> CGFloat {
    guard let lmk, let leftP = lmk.points["left_eye"]?.first, let rightP = lmk.points["right_eye"]?.first else {
        return size.width * 0.18 // fallback
    }
    let lp = CGPoint(x: leftP.x * size.width, y: leftP.y * size.height)
    let rp = CGPoint(x: rightP.x * size.width, y: rightP.y * size.height)
    return hypot(lp.x - rp.x, lp.y - rp.y)
}


