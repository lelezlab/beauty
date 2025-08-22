import SwiftUI
import UIKit

struct AnalysisView: View {
	let front: UIImage
	@State private var landmarks: FacialLandmarksResult?
	@State private var metrics: AestheticsMetrics?
	@State private var isLoading = false
	@State private var suggestions: [Suggestion] = []
	@EnvironmentObject private var results: ResultsStore
    @State private var showGoldenMask: Bool = false
    @State private var showingHelp: Bool = false

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 16) {
				ZStack(alignment: .topLeading) {
					Image(uiImage: front).resizable().scaledToFit().cornerRadius(8)
					if let l = landmarks { LandmarksOverlay(landmarks: l).padding(8) }
                    if showGoldenMask { GoldenGuidesOverlay(landmarks: landmarks, metrics: metrics).padding(8) }
				}
				if let m = metrics { metricsSection(m) }
				// 新增：风格词与差异热点
				if let m = metrics, let lmk = landmarks {
					let words = AestheticsInsights.styleWords(from: m)
					if !words.isEmpty {
						Text("风格词：" + words.joined(separator: "、")).font(.subheadline)
					}
					let hs = AestheticsInsights.hotspots(from: lmk, imageSize: front.size)
					if !hs.isEmpty {
						Text("差异热点：").font(.subheadline)
						ForEach(hs) { h in
							Text("• \(h.title) 偏差 \(h.deltaMM, specifier: \"%.1f\")mm")
								.font(.footnote)
						}
					}
				}
				if !suggestions.isEmpty { suggestionsSection }
                Toggle("叠加黄金比例面罩", isOn: $showGoldenMask)
				NavigationLink("心理健康守护 / BDD 自评") { BDDSelfAssessmentView() }
				NavigationLink("查看隆鼻术式选项") { ProcedureListView(category: "nose") }
				if let m = metrics {
					// 快速查看差异摘要
					VStack(alignment: .leading, spacing: 6) {
						Text("关键差异摘要").font(.headline)
						Text(String(format: "三庭 %.2f → 1.00", m.threeFacialZonesRatio)).font(.caption).monospaced()
						Text(String(format: "五眼 %.2f → 1.00", m.fiveEyesRatio)).font(.caption).monospaced()
						Text(String(format: "鼻唇角 %.1f° → 103°", m.nasolabialAngleDegrees)).font(.caption).monospaced()
						Text(String(format: "下巴投影 %.2f → 1.00", m.chinProjectionRatio)).font(.caption).monospaced()
						Text(String(format: "宽高比 %.2f → 0.75", m.faceWidthToHeight)).font(.caption).monospaced()
						// 可操作的调整量（估算）
						let chinDeltaPct = max(0, 1.0 - m.chinProjectionRatio)
						let fiveEyesDeltaPct = max(0, 1.0 - m.fiveEyesRatio)
						Text(String(format: "建议：下巴前移约 %.0f%%；双眼（含留白）收敛约 %.0f%%", chinDeltaPct*100, fiveEyesDeltaPct*100))
							.font(.caption2)
							.foregroundStyle(.orange)
						// 以当前 IPD 估算 mm（仅提示）
						let _: Double = {
							guard let l = landmarks,
							      let lp = l.points["left_eye"]?.first,
							      let rp = l.points["right_eye"]?.first else { return 0 }
							return Double(hypot(lp.x - rp.x, lp.y - rp.y))
						}()
						let ipdMM = UserDefaults.standard.object(forKey: "gm_ipd_mm") as? Double ?? 63.0
						let chinMM = chinDeltaPct * ipdMM
						let fiveMM = fiveEyesDeltaPct * ipdMM
						Text(String(format: "约需：下巴 %.1fmm；五眼 %.1fmm（基于 IPD=%.0fmm）", chinMM, fiveMM, ipdMM))
							.font(.caption2)
							.foregroundStyle(.secondary)
					}
				}
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
			let conf = ConfidenceEstimator.score(from: BeautyTelemetryService.shared.lastQC ?? BTCaptureQC(blurScore: 0.2, exposureMean: 0.6, faceCoverage: 0.6, yaw: nil, pitch: nil, roll: nil, focalEq: nil, distanceBucket: 3, aeLocked: nil, awbLocked: nil, alignScore: 0.6))
			let mp = BTMetricsPayload(
				threeZones: Double(m.threeFacialZonesRatio),
				fiveEyes: Double(m.fiveEyesRatio),
				nasolabialDeg: Double(m.nasolabialAngleDegrees),
				chinProjection: Double(m.chinProjectionRatio),
				faceWH: Double(m.faceWidthToHeight),
				confidence: conf
			)
			BeautyTelemetryService.shared.recordGeometry(points: l.points, metrics: mp)
			// 使用更精确的评估映射
			let assess = AestheticsAssessor.assess(metrics: m)
			let sug = assess.items.map { item in
				Suggestion(title: item.key, reason: String(format: "偏差: %.2f", item.delta), knowledgeKey: item.key)
			}
			self.suggestions = sug
			results.update(metrics: m, suggestions: sug)
		}
	}

	@ViewBuilder private func metricsSection(_ m: AestheticsMetrics) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				Text("三庭五眼与关键指标").font(.headline)
				Button { showingHelp.toggle() } label: { Image(systemName: "info.circle") }
					.buttonStyle(.plain)
				Spacer()
				if let qc = BeautyTelemetryService.shared.lastQC {
					let c = ConfidenceEstimator.score(from: qc)
					Text(String(format: "可信度 %.0f%%", c*100)).font(.caption).padding(6).background(Color.green.opacity(0.85), in: Capsule()).foregroundStyle(.white)
				}
			}
			metricBar(name: "三庭综合比", value: m.threeFacialZonesRatio, target: 1.0, range: 0.6...1.4, format: "%.2f")
			metricBar(name: "五眼比例", value: m.fiveEyesRatio, target: 1.0, range: 0.6...1.4, format: "%.2f")
			metricBar(name: "鼻唇角(°)", value: m.nasolabialAngleDegrees, target: 103, range: 85...120, format: "%.1f")
			metricBar(name: "下巴投影", value: m.chinProjectionRatio, target: 1.0, range: 0.7...1.3, format: "%.2f")
			metricBar(name: "面宽高比", value: m.faceWidthToHeight, target: 0.75, range: 0.5...1.1, format: "%.2f")
			Text("说明：靠近目标值更理想；三庭/五眼目标≈1.00，鼻唇角≈103°，面宽高比≈0.75。").font(.caption).foregroundStyle(.secondary)
		}
		.sheet(isPresented: $showingHelp) { MetricHelpSheet() }

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
					let chosen: Procedure? = CaptureStore.shared.selectedProcedure
					let region = RegionManager().displayName
					let mp: BTMetricsPayload? = {
						if let m = metrics {
							let conf = ConfidenceEstimator.score(from: BeautyTelemetryService.shared.lastQC ?? BTCaptureQC(blurScore: 0.2, exposureMean: 0.6, faceCoverage: 0.6, yaw: nil, pitch: nil, roll: nil, focalEq: nil, distanceBucket: 3, aeLocked: nil, awbLocked: nil, alignScore: 0.6))
							return BTMetricsPayload(
								threeZones: Double(m.threeFacialZonesRatio),
								fiveEyes: Double(m.fiveEyesRatio),
								nasolabialDeg: Double(m.nasolabialAngleDegrees),
								chinProjection: Double(m.chinProjectionRatio),
								faceWH: Double(m.faceWidthToHeight),
								confidence: conf
							)
						}
						return nil
					}()
					let cons: Double? = {
						let fl = CaptureStore.shared.frontLandmarks
						let ll = CaptureStore.shared.leftLandmarks
						let rl = CaptureStore.shared.rightLandmarks
						return MultiViewMorpher.consistencyScore(front: fl, left: ll, right: rl)
					}()
					if let combo = ExportService.compositeBeforeAfter(before: front, after: preview, watermark: "beauty demo - not for medical use", layout: .vertical, showAB: true, regionText: region),
					   let pdf = ExportService.makePDF(from: combo, disclaimer: "本PDF仅作审美模拟参考，不构成医疗建议；请以专业医生面诊为准。", procedure: chosen, metrics: mp, location: region, timestamp: Date(), bddScore: BeautyTelemetryService.shared.lastBDDScore, consistency: cons) {
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
					Button("记录查看") { BeautyTelemetryService.shared.recordKnowledge(key: s.knowledgeKey, action: "open_from_suggestion") }
					NavigationLink("在知识库中打开") { KnowledgeDetailView(article: KnowledgeBase.article(for: s.knowledgeKey) ?? KnowledgeArticle(key: s.knowledgeKey, title: s.title, summary: s.reason, sections: [])) }
					if let dest = ProcedureSimulationRouter.destination(forKey: s.knowledgeKey) {
						NavigationLink("去术后模拟") { dest }
					}
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

private struct MetricHelpSheet: View {
    var body: some View {
        NavigationStack {
            List {
                Section("三庭") { Text("额头-鼻底-下巴三段的相对比例，目标≈1.00 更均衡") }
                Section("五眼") { Text("面宽约等于五个眼宽的总和，目标≈1.00 更均衡") }
                Section("鼻唇角") { Text("鼻柱与上唇的夹角，常见理想值约 95°–110°，默认目标≈103°") }
                Section("下巴投影") { Text("下巴前后投影与面部整体协调度，目标≈1.00") }
                Section("面宽高比") { Text("脸部宽度/高度，默认目标≈0.75，不同脸型会有差异") }
            }
            .navigationTitle("指标说明")
        }
    }
}


