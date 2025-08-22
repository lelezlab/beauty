import CoreGraphics

/// Simple exponential smoothing for landmark tracks; can be upgraded to Kalman later.
final class LandmarkSmoother {
    private var last: [CGPoint] = []
    private let alpha: CGFloat
    init(alpha: CGFloat = 0.5) { self.alpha = alpha }

    func process(points: [CGPoint], t: Double) -> [CGPoint] {
        guard !last.isEmpty, last.count == points.count else { last = points; return points }
        var out: [CGPoint] = []
        for i in 0..<points.count {
            let p = points[i]
            let l = last[i]
            let nx = alpha*p.x + (1-alpha)*l.x
            let ny = alpha*p.y + (1-alpha)*l.y
            out.append(CGPoint(x: nx, y: ny))
        }
        last = out
        return out
    }
}


