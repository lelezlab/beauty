import SwiftUI

struct GoldenMask2DOverlay: View {
    let landmarks: FacialLandmarksResult?
    var body: some View {
        GeometryReader { geo in
            let devs = MaskDeviationAnalyzer.analyze2D(landmarks: landmarks, imageSize: geo.size)
            ZStack {
                // 简化线框：十字+面部区域参考
                Path { p in
                    p.move(to: CGPoint(x: geo.size.width/2, y: 0))
                    p.addLine(to: CGPoint(x: geo.size.width/2, y: geo.size.height))
                    p.move(to: CGPoint(x: 0, y: geo.size.height/2))
                    p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height/2))
                }
                .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
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


