import SwiftUI
import CoreGraphics

struct DoctorOverlayView: View {
    let size: CGSize
    let landmarks: [String: [CGPoint]]

    var body: some View {
        Canvas { ctx, _ in
            // Midline
            let midX = size.width/2
            var mid = Path()
            mid.move(to: CGPoint(x: midX, y: 0))
            mid.addLine(to: CGPoint(x: midX, y: size.height))
            ctx.stroke(mid, with: .color(.red.opacity(0.5)), style: StrokeStyle(lineWidth: 1, dash: [4,4]))

            // Thirds
            let h = size.height
            for i in 1...2 {
                let y = CGFloat(i) * h/3
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(p, with: .color(.yellow.opacity(0.5)), style: StrokeStyle(lineWidth: 1, dash: [3,3]))
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}


