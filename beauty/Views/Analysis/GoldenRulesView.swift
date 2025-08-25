import SwiftUI

struct GoldenRulesView: View {
    let score: GoldenRulesScore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("美丽黄金法则评分：\(Int(round(score.total*100)))")
                .font(.headline)
            ForEach(Array(score.details.keys).sorted(), id: \.self) { key in
                if let v = score.details[key] {
                    HStack {
                        Text(key)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.gray.opacity(0.2))
                                Capsule().fill(v > 0.8 ? .green : (v > 0.5 ? .orange : .red))
                                    .frame(width: geo.size.width * CGFloat(min(max(v,0),1)))
                            }
                        }.frame(height: 8)
                        Text(String(format: "%.2f", v))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
    }
}


