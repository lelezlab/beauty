import SwiftUI

struct AnalysisView: View {
	let front: UIImage
	@State private var landmarks: FacialLandmarksResult?
	@State private var metrics: AestheticsMetrics?
	@State private var isLoading = false

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 16) {
				Image(uiImage: front).resizable().scaledToFit().cornerRadius(8)
				if let m = metrics { metricsSection(m) }
				stylePresets
			}
			.padding()
		}
		.navigationTitle("美学分析")
		.task { await analyze() }
	}

	private func analyze() async {
		guard !isLoading else { return }
		isLoading = true
		defer { isLoading = false }
		let analyzer = FaceAnalyzer()
		if let l = try? await analyzer.detectLandmarks(in: front) {
			landmarks = l
			metrics = MetricsCalculator.compute(from: l, imageSize: front.size)
		}
	}

	@ViewBuilder private func metricsSection(_ m: AestheticsMetrics) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("三庭五眼与关键指标").font(.headline)
			metricRow("三庭综合比", String(format: "%.2f", m.threeFacialZonesRatio))
			metricRow("五眼比例", String(format: "%.2f", m.fiveEyesRatio))
			metricRow("鼻唇角(°)", String(format: "%.1f", m.nasolabialAngleDegrees))
			metricRow("下巴投影", String(format: "%.2f", m.chinProjectionRatio))
			metricRow("面宽高比", String(format: "%.2f", m.faceWidthToHeight))
		}
	}

	private func metricRow(_ name: String, _ value: String) -> some View {
		HStack { Text(name); Spacer(); Text(value).monospaced() }
			.padding(10)
			.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
	}

	private var stylePresets: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("一键模板").font(.headline)
			ScrollView(.horizontal, showsIndicators: false) {
				HStack {
					ForEach(StylePreset.allCases) { preset in
						NavigationLink(preset.rawValue.localizedCapitalized) {
							if let l = landmarks {
								PresetPreviewView(image: front, landmarks: l, preset: preset)
							}
						}
						.buttonStyle(.bordered)
					}
				}
			}
		}
	}
}

private struct PresetPreviewView: View {
	let image: UIImage
	let landmarks: FacialLandmarksResult
	let preset: StylePreset
	private let renderer = MorphingRenderer()

	var body: some View {
		let preview = renderer.applyPreset(preset, to: image, landmarks: landmarks)
		Image(uiImage: preview).resizable().scaledToFit().padding()
	}
}


