import SwiftUI
import UIKit

struct AnalysisView: View {
	let front: UIImage
	@State private var landmarks: FacialLandmarksResult?
	@State private var metrics: AestheticsMetrics?
	@State private var isLoading = false
	@State private var suggestions: [Suggestion] = []

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 16) {
				ZStack(alignment: .topLeading) {
					Image(uiImage: front).resizable().scaledToFit().cornerRadius(8)
					if let l = landmarks { LandmarksOverlay(landmarks: l).padding(8) }
				}
				if let m = metrics { metricsSection(m) }
				if !suggestions.isEmpty { suggestionsSection }
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
			CaptureStore.shared.frontLandmarks = l
			let m = MetricsCalculator.compute(from: l, imageSize: front.size)
			metrics = m
			let mp = BTMetricsPayload(
				threeZones: Double(m.threeFacialZonesRatio),
				fiveEyes: Double(m.fiveEyesRatio),
				nasolabialDeg: Double(m.nasolabialAngleDegrees),
				chinProjection: Double(m.chinProjectionRatio),
				faceWH: Double(m.faceWidthToHeight)
			)
			BeautyTelemetryService.shared.recordGeometry(points: l.points, metrics: mp)
			suggestions = SuggestionsEngine.generate(from: m)
		}
	}

	@ViewBuilder private func metricsSection(_ m: AestheticsMetrics) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("三庭五眼与关键指标").font(.headline)
			metricBar(name: "三庭综合比", value: m.threeFacialZonesRatio, target: 1.0, range: 0.6...1.4, format: "%.2f")
			metricBar(name: "五眼比例", value: m.fiveEyesRatio, target: 1.0, range: 0.6...1.4, format: "%.2f")
			metricBar(name: "鼻唇角(°)", value: m.nasolabialAngleDegrees, target: 103, range: 85...120, format: "%.1f")
			metricBar(name: "下巴投影", value: m.chinProjectionRatio, target: 1.0, range: 0.7...1.3, format: "%.2f")
			metricBar(name: "面宽高比", value: m.faceWidthToHeight, target: 0.75, range: 0.5...1.1, format: "%.2f")
		}

		// 简易雷达图（归一化示意）
		let radarItems: [RadarChartView.Item] = [
			.init(name: "三庭", value: clamp01((m.threeFacialZonesRatio-0.6)/0.8)),
			.init(name: "五眼", value: clamp01((m.fiveEyesRatio-0.6)/0.8)),
			.init(name: "鼻唇角", value: clamp01((Double(m.nasolabialAngleDegrees)-85.0)/35.0)),
			.init(name: "下巴", value: clamp01((m.chinProjectionRatio-0.7)/0.6)),
			.init(name: "宽高比", value: clamp01((m.faceWidthToHeight-0.5)/0.6))
		]
		RadarChartView(items: radarItems)
	}

	private func metricBar(name: String, value: Double, target: Double, range: ClosedRange<Double>, format: String) -> some View {
		let norm = max(0, min(1, (value - range.lowerBound) / (range.upperBound - range.lowerBound)))
		let delta = abs(value - target)
		let color: Color = delta < 0.05 * (range.upperBound - range.lowerBound) ? .green : (delta < 0.1 ? .orange : .red)
		return AnyView(VStack(alignment: .leading, spacing: 6) {
			HStack { Text(name); Spacer(); Text(String(format: format, value)).monospaced() }
				.font(.subheadline)
			ZStack(alignment: .leading) {
				RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.15)).frame(height: 8)
				RoundedRectangle(cornerRadius: 4).fill(color).frame(width: CGFloat(norm)*240.0, height: 8)
			}
		})
	}
}

extension AnalysisView {
	private var stylePresets: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("一键模板").font(.headline)
			ScrollView(.horizontal, showsIndicators: false) {
				HStack {
					ForEach(StylePreset.allCases) { preset in
						NavigationLink(preset.rawValue.localizedCapitalized) {
							if let lmk = landmarks {
								PresetPreviewView(image: front, landmarks: lmk, preset: preset)
							}
						}
						.buttonStyle(.bordered)
					}
				}
			}
			// 导出
			if let lmk = landmarks {
				let preview = MorphingRenderer().applyPreset(.natural, to: front, landmarks: lmk)
				Button("导出前后对比PDF") {
					if let combo = ExportService.compositeBeforeAfter(before: front, after: preview, watermark: "beauty demo - not for medical use"),
					   let pdf = ExportService.makePDF(from: combo, disclaimer: "本PDF仅作审美模拟参考，不构成医疗建议；请以专业医生面诊为准。") {
						share(data: pdf, fileName: "beauty_before_after.pdf")
					}
				}
			}
		}
	}
}

private func clamp01(_ v: Double) -> Double { max(0, min(1, v)) }

private func share(data: Data, fileName: String) {
	let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
	try? data.write(to: tmp)
	let av = UIActivityViewController(activityItems: [tmp], applicationActivities: nil)
	UIApplication.shared.connectedScenes
		.compactMap { ($0 as? UIWindowScene)?.keyWindow }
		.first?
		.rootViewController?
		.present(av, animated: true)
}

private struct LandmarksOverlay: View {
	let landmarks: FacialLandmarksResult
	var body: some View {
		Canvas { ctx, size in
			let color = Color.green
			for (_, pts) in landmarks.points {
				guard !pts.isEmpty else { continue }
				var path = Path()
				let s = CGSize(width: size.width, height: size.height)
				let start = CGPoint(x: pts[0].x * s.width, y: pts[0].y * s.height)
				path.move(to: start)
				for p in pts.dropFirst() {
					path.addLine(to: CGPoint(x: p.x * s.width, y: p.y * s.height))
				}
				ctx.stroke(path, with: .color(color.opacity(0.7)), lineWidth: 1)
			}
		}
	}
}

private struct KnowledgeDetailPlaceholder: View {
	let key: String
	var body: some View {
		let article = KnowledgeBase.article(for: key)
		return ScrollView {
			VStack(alignment: .leading, spacing: 12) {
				Text(article?.title ?? "知识点").font(.title3).bold()
				if let s = article?.summary { Text(s).foregroundStyle(.secondary) }
				ForEach(article?.sections ?? [], id: \.heading) { section in
					VStack(alignment: .leading, spacing: 6) {
						Text(section.heading).bold()
						Text(section.body)
					}
				}
			}
			.padding()
		}
		.navigationTitle("知识库")
	}
}

private extension AnalysisView {
	var suggestionsSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("建议与知识点").font(.headline)
			ForEach(suggestions) { s in
				VStack(alignment: .leading, spacing: 4) {
					Text(s.title).bold()
					Text(s.reason).font(.caption).foregroundStyle(.secondary)
					NavigationLink("查看对应知识点") { KnowledgeDetailPlaceholder(key: s.knowledgeKey) }
				}
				.padding(10)
				.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
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


