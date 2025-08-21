import SwiftUI

struct ResultsDashboardView: View {
    // 输入：可从分析页传入，也可为空则显示示例/占位
    let metrics: AestheticsMetrics?
    let suggestions: [Suggestion]

    @State private var selectedTab: String = "总览"
    private let tabs = ["总览", "毛孔", "皱纹", "敏感", "下垂", "浮肿", "骨肉比", "变美推荐"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                tabsBar
                scoreGauge
                metricBars
                if !suggestions.isEmpty { topSolutions }
            }
            .padding()
        }
        .navigationTitle("分析总览")
    }

    private var tabsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tabs, id: \.self) { t in
                    Text(t)
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(selectedTab == t ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1), in: Capsule())
                        .onTapGesture { selectedTab = t }
                }
            }
        }
    }

    private var scoreGauge: some View {
        let score = overallScore()
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline) {
                Text("今日肌分").font(.headline)
                Spacer()
                Text("\(Int(score))/100").font(.title).bold()
            }
            ProgressView(value: score/100.0)
                .tint(score >= 80 ? .green : (score >= 60 ? .orange : .red))
        }
    }

    private var metricBars: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("关键维度").font(.headline)
            if let m = metrics {
                bar("三庭", value: normalize(m.threeFacialZonesRatio, 0.6, 1.4))
                bar("五眼", value: normalize(m.fiveEyesRatio, 0.6, 1.4))
                bar("鼻唇角", value: normalize(m.nasolabialAngleDegrees, 85, 120))
                bar("下巴投影", value: normalize(m.chinProjectionRatio, 0.7, 1.3))
                bar("宽高比", value: normalize(m.faceWidthToHeight, 0.5, 1.1))
            } else {
                Text("暂无数据，先去拍摄并分析吧。").foregroundStyle(.secondary)
            }
        }
    }

    private var topSolutions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TOP 推荐方案").font(.headline)
            ForEach(suggestions.prefix(3)) { s in
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.title).bold()
                    Text(s.reason).font(.caption).foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func bar(_ name: String, value: Double) -> some View {
        let v = max(0, min(1, value))
        return HStack {
            Text(name).frame(width: 60, alignment: .leading)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.15)).frame(height: 8)
                RoundedRectangle(cornerRadius: 4).fill(Color.accentColor).frame(width: 220 * v, height: 8)
            }
        }
    }

    private func normalize(_ x: Double, _ min: Double, _ max: Double) -> Double {
        (x - min) / (max - min)
    }

    private func overallScore() -> Double {
        guard let m = metrics else { return 60 }
        let components = [
            normalize(m.threeFacialZonesRatio, 0.6, 1.4),
            normalize(m.fiveEyesRatio, 0.6, 1.4),
            normalize(m.nasolabialAngleDegrees, 85, 120),
            normalize(m.chinProjectionRatio, 0.7, 1.3),
            normalize(m.faceWidthToHeight, 0.5, 1.1)
        ]
        let avg = components.map { max(0, min(1, $0)) }.reduce(0, +) / Double(components.count)
        return avg * 100
    }
}


