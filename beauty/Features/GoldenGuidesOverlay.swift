import SwiftUI

struct GoldenGuidesOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // 五等分（水平）
                ForEach(1..<5) { i in
                    Path { p in let y = h * CGFloat(i) / 5.0; p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: w, y: y)) }
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                }
                // 三等分（垂直）
                ForEach(1..<3) { i in
                    Path { p in let x = w * CGFloat(i) / 3.0; p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: h)) }
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                }
            }
        }
    }
}


