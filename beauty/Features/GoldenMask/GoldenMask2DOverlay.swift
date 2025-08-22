import SwiftUI

struct GoldenMask2DOverlay: View {
    let landmarks: FacialLandmarksResult?
    init(landmarks: FacialLandmarksResult?) { self.landmarks = landmarks }
    var body: some View {
        GeometryReader { geo in
            // 加载可选的黄金面罩 spec（若存在）
            let spec: GoldenSpec? = {
                if let url = Bundle.main.url(forResource: "specs/golden_mask/golden_mask_anchors", withExtension: "json") { return GoldenMaskParser.loadSpec(from: url) }
                return nil
            }()
            let devs = MaskDeviationAnalyzer.analyze2D(landmarks: landmarks, imageSize: geo.size, spec: spec)
            let byId = Dictionary(uniqueKeysWithValues: devs.map { ($0.id, $0) })
            ZStack {
                // 简化线框：十字+面部区域参考
                Path { p in
                    p.move(to: CGPoint(x: geo.size.width/2, y: 0))
                    p.addLine(to: CGPoint(x: geo.size.width/2, y: geo.size.height))
                    p.move(to: CGPoint(x: 0, y: geo.size.height/2))
                    p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height/2))
                }
                .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                // 若有曲线定义，按锚点连线并根据端点偏差着色
                if let curves = spec?.curves {
                    let arr = Array(curves)
                    ForEach(arr, id: \.name) { c in
                        var avg: Double = 0; var count: Double = 0
                        var pts: [CGPoint] = []
                        for name in c.through {
                            if let dv = byId[name] { pts.append(dv.point); avg += dv.deltaMM; count += 1 }
                        }
                        if pts.count >= 2 {
                            let color: Color = {
                                let m = (count>0 ? avg/count : 0)
                                if m <= 1 { return .green } else if m <= 3 { return .yellow } else { return .red }
                            }()
                            Path { p in
                                p.move(to: pts[0]); for pt in pts.dropFirst() { p.addLine(to: pt) }
                            }.stroke(color.opacity(0.8), lineWidth: 2)
                        }
                    }
                }
                // 标注偏差点
                ForEach(devs, id: \.id) { d in
                    let color: Color = d.deltaMM <= 1 ? .green : (d.deltaMM <= 3 ? .yellow : .red)
                    Circle()
                        .strokeBorder(color, lineWidth: 2)
                        .background(Circle().fill(color.opacity(0.15)))
                        .frame(width: 10, height: 10)
                        .position(d.point)
                        .overlay(alignment: .topLeading) {
                            Text(String(format: "%.1fmm", d.deltaMM)).font(.caption2).foregroundStyle(color)
                                .padding(2).background(.ultraThinMaterial, in: Capsule())
                                .offset(x: 6, y: -6)
                        }
                }
            }
        }
        .allowsHitTesting(false)
    }
}


