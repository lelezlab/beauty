import SwiftUI

struct RadarChartView: View {
    struct Item: Identifiable { let id = UUID(); let name: String; let value: Double }
    let items: [Item]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, 220)
            ZStack {
                // grid
                ForEach(1...4, id: \.self) { i in
                    polygonPath(size: size, factor: Double(i)/4.0)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                }
                // labels
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    let angle = angleFor(index: idx)
                    let r = size/2 + 10
                    let x = cos(angle) * r
                    let y = sin(angle) * r
                    Text(item.name).font(.caption2)
                        .position(x: size/2 + x, y: size/2 + y)
                }
                // values
                polygonForValues(size: size)
                    .fill(Color.blue.opacity(0.2))
                polygonForValues(size: size)
                    .stroke(Color.blue, lineWidth: 2)
            }
            .frame(width: size, height: size)
        }
        .frame(height: 240)
    }

    private func angleFor(index: Int) -> CGFloat {
        let step = 2 * Double.pi / Double(items.count)
        return CGFloat(step * Double(index) - Double.pi/2)
    }

    private func point(size: CGFloat, value: Double, index: Int) -> CGPoint {
        let r = size/2 * CGFloat(max(0, min(1, value)))
        let angle = angleFor(index: index)
        return CGPoint(x: size/2 + cos(angle)*r, y: size/2 + sin(angle)*r)
    }

    private func polygonForValues(size: CGFloat) -> Path {
        var path = Path()
        guard !items.isEmpty else { return path }
        let p0 = point(size: size, value: items[0].value, index: 0)
        path.move(to: p0)
        for idx in 1..<items.count {
            path.addLine(to: point(size: size, value: items[idx].value, index: idx))
        }
        path.closeSubpath()
        return path
    }

    private func polygonPath(size: CGFloat, factor: Double) -> Path {
        var path = Path()
        guard !items.isEmpty else { return path }
        let p0 = point(size: size, value: factor, index: 0)
        path.move(to: p0)
        for idx in 1..<items.count {
            path.addLine(to: point(size: size, value: factor, index: idx))
        }
        path.closeSubpath()
        return path
    }
}


