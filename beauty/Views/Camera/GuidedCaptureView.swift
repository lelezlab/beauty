import SwiftUI
import UIKit
import AVFoundation
import SwiftData

struct GuidedCaptureView: View {
	@StateObject private var camera = CameraSession()
	@State private var front: UIImage?
	@State private var left: UIImage?
	@State private var right: UIImage?
	@State private var step: Int = 0
	@State private var requireQualityPass: Bool = false
	@State private var showConsent: Bool = false
	@State private var showTips: Bool = true
	@Environment(\.modelContext) private var modelContext
	var onFinished: (UIImage, UIImage, UIImage) -> Void

	var body: some View {
		VStack(spacing: 12) {
			ZStack(alignment: .top) {
				VideoPreviewView(session: camera.captureSession)
					.allowsHitTesting(false)
					.overlay { guideOverlay.allowsHitTesting(false) }
					.overlay { if FeatureFlags.goldenGuidesEnabled { GoldenGuidesOverlay(landmarks: CaptureStore.shared.frontLandmarks).allowsHitTesting(false) } }
				.overlay(alignment: .top) {
					HStack { levelIndicator; qualityBadges; distanceHint; alignScore; confidenceTag }
						.padding(8)
						.allowsHitTesting(false)
				}
				// 底部浮层工具条，确保可点击
				.overlay(alignment: .bottom) { bottomToolbar }
				GuidedTipsOverlay(visible: $showTips)
			}
			Text(instructionText)
				.font(.headline)
				.padding(.top, 4)
			// 原位置保留但隐藏，避免布局大改动
			Toggle("必须通过质检后才能拍照", isOn: $requireQualityPass)
				.toggleStyle(.switch)
				.padding(.bottom, 2)
				.hidden()
			HStack { Button("拍照") { capture() }; Button("重拍") { resetCurrent() } }.hidden()
			if !canCapture { HStack { Text(gateReason); Button("强制拍照") { capture() } }.hidden() }
			HStack {
				thumbnail(front)
				thumbnail(left)
				thumbnail(right)
			}
			.padding(.top, 8)
			if front != nil && left != nil && right != nil {
				Text("已完成拍摄，点击底部“完成”进入分析")
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}
		}
		.onAppear {
			if ConsentManager.shared.state == .unknown { showConsent = true }
			DispatchQueue.main.asyncAfter(deadline: .now()+4) { withAnimation { showTips = false } }
		}
		.sheet(isPresented: $showConsent) { ConsentFlowView() }
	}

	private var instructionText: String {
		switch step {
		case 0: return "正面视图：保持水平、光线充足"
		case 1: return "左侧视图：头部左转 90°"
		default: return "右侧视图：头部右转 90°"
		}
	}

	private var canCapture: Bool { !requireQualityPass || (!camera.exposureTooLow && !camera.isBlurry) }

	private var gateReason: String {
		var reasons: [String] = []
		if camera.exposureTooLow { reasons.append("光线不足") }
		if camera.isBlurry { reasons.append("画面模糊") }
		return reasons.isEmpty ? "质检未通过" : reasons.joined(separator: " / ")
	}

	@ViewBuilder private var bottomToolbar: some View {
		VStack(spacing: 8) {
			if !canCapture {
				HStack(spacing: 8) {
					Text(gateReason).font(.caption).foregroundStyle(.secondary)
					Spacer()
					Button("强制拍照") { capture() }.buttonStyle(.bordered)
				}
			}
			HStack(spacing: 12) {
				Button { showingTips.toggle() } label: { Label("拍摄要点", systemImage: "questionmark.circle") }
					.buttonStyle(.bordered)
				Toggle("必须通过质检后才能拍照", isOn: $requireQualityPass)
					.toggleStyle(.switch)
				Spacer()
				Button("重拍") { resetCurrent() }
					.disabled(currentImage == nil)
				Button("拍照") { capture() }
					.buttonStyle(.borderedProminent)
					.disabled(!canCapture)
			}
			if front != nil && left != nil && right != nil {
				Button("完成") {
					onFinished(front!, left!, right!)
					CaptureStore.shared.saveSession(front: front!, left: left!, right: right!)
					let s = BeautySession(frontImage: front, leftImage: left, rightImage: right)
					modelContext.insert(s)
				}
				.buttonStyle(.borderedProminent)
			}
		}
		.padding(.horizontal, 12)
		.padding(.top, 8)
		.padding(.bottom, 12)
		.frame(maxWidth: .infinity)
		.background(.ultraThinMaterial)
		.ignoresSafeArea(edges: .bottom)
		.zIndex(1000)
		.sheet(isPresented: $showingTips) { CaptureTipsSheet() }
	}

	@State private var showingTips: Bool = false

	private var currentImage: UIImage? {
		switch step { case 0: return front; case 1: return left; default: return right }
	}

	private func capture() { camera.capturePhoto { image in
		guard let image else { return }
		// 埋点：基础 QC（示意，后续可接真实相机参数）
		let qc = BTCaptureQC(
			blurScore: camera.isBlurry ? 1.0 : 0.0,
			exposureMean: camera.exposureTooLow ? 0.1 : 0.6,
			faceCoverage: 0.6,
			yaw: Double(camera.levelDegrees),
			pitch: nil,
			roll: nil,
			focalEq: camera.focalEqMM,
			distanceBucket: estimateDistanceBucket(),
			aeLocked: camera.aeLocked,
			awbLocked: camera.awbLocked,
			alignScore: computeAlignScore()
		)
		BeautyTelemetryService.shared.recordCapture(qc: qc)
		switch step {
		case 0:
			front = image; CaptureStore.shared.frontImage = image
			Task { if let lmk = try? await FaceAnalyzer().detectLandmarks(in: image) { CaptureStore.shared.frontLandmarks = lmk } }
		case 1:
			left = image; CaptureStore.shared.leftImage = image
			Task { if let lmk = try? await FaceAnalyzer().detectLandmarks(in: image) { CaptureStore.shared.leftLandmarks = lmk } }
		default:
			right = image; CaptureStore.shared.rightImage = image
			Task { if let lmk = try? await FaceAnalyzer().detectLandmarks(in: image) { CaptureStore.shared.rightLandmarks = lmk } }
		}
		step = min(step + 1, 2)
	} }

	private func resetCurrent() { switch step { case 0: front = nil; case 1: left = nil; default: right = nil } }

	private func estimateDistanceBucket() -> Int {
		// 简化：基于人脸覆盖率与 FOV 估计 1..5 桶；此处先用静态 3，后续接入人脸框占比
		return 3
	}

	private var levelIndicator: some View {
		HStack(spacing: 6) {
			Image(systemName: abs(camera.levelDegrees) < 2 ? "水平线" : "line.horizontal.3")
			Text(String(format: "%.1f°", camera.levelDegrees))
		}
		.padding(6)
		.background(.ultraThinMaterial, in: Capsule())
	}

	private var qualityBadges: some View {
		HStack(spacing: 6) {
			if camera.exposureTooLow { badge("光线不足") }
			if camera.isBlurry { badge("画面模糊") }
		}
	}

	private var distanceHint: some View {
		let b = camera.distanceBucket
		let text: String = {
			switch b { case 1: return "远一点"; case 2: return "稍远"; case 3: return "距离合适"; case 4: return "稍近"; default: return "近一点" }
		}()
		return Text(text)
			.font(.caption)
			.padding(6)
			.background(Color.blue.opacity(0.8), in: Capsule())
			.foregroundStyle(.white)
	}

	private var alignScore: some View {
		let score = computeAlignScore()
		return VStack(alignment: .leading) {
			Text(String(format: "对齐 %.0f%%", score*100)).font(.caption2)
			ZStack(alignment: .leading) {
				RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.25)).frame(width: 70, height: 6)
				RoundedRectangle(cornerRadius: 3).fill(Color.green).frame(width: 70*score, height: 6)
			}
		}
		.padding(6)
		.background(.ultraThinMaterial, in: Capsule())
	}

	private var confidenceTag: some View {
		let qc = BTCaptureQC(
			blurScore: camera.isBlurry ? 1.0 : 0.0,
			exposureMean: camera.exposureTooLow ? 0.1 : 0.6,
			faceCoverage: 0.6,
			yaw: Double(camera.levelDegrees),
			pitch: nil,
			roll: nil,
			focalEq: camera.focalEqMM,
			distanceBucket: estimateDistanceBucket(),
			aeLocked: camera.aeLocked,
			awbLocked: camera.awbLocked,
			alignScore: computeAlignScore()
		)
		let c = ConfidenceEstimator.score(from: qc)
		return Text(String(format: "可信度 %.0f%%", c*100))
			.font(.caption2)
			.padding(6)
			.background(Color.green.opacity(0.85), in: Capsule())
			.foregroundStyle(.white)
	}

	private func computeAlignScore() -> Double {
		let angleScore = max(0, 1 - abs(camera.levelDegrees)/10.0)
		let distScore = 1 - abs(Double(camera.distanceBucket) - 3)/2.0
		let expoScore = camera.exposureTooLow ? 0.5 : 1.0
		return max(0.0, min(1.0, 0.5*angleScore + 0.3*distScore + 0.2*expoScore))
	}

	private var guideOverlay: some View {
		GeometryReader { geo in
			let w = geo.size.width
			let h = geo.size.height
			ZStack {
				// 十字辅助线
				Path { p in
					p.move(to: CGPoint(x: w/2, y: 0)); p.addLine(to: CGPoint(x: w/2, y: h))
					p.move(to: CGPoint(x: 0, y: h/2)); p.addLine(to: CGPoint(x: w, y: h/2))
				}
				.stroke(Color.white.opacity(0.25), lineWidth: 1)

				// 面部轮廓遮罩（正面椭圆，侧面圆角矩形）
				Path { p in
					let rect = CGRect(x: w*0.2, y: h*0.15, width: w*0.6, height: h*0.7)
					if step == 0 { p.addEllipse(in: rect) }
					else { p.addRoundedRect(in: rect, cornerSize: CGSize(width: w*0.3, height: h*0.35)) }
				}
				.stroke(Color.yellow.opacity(0.35), lineWidth: 2)
			}
		}
	}

	private func badge(_ text: String) -> some View {
		Text(text)
			.font(.caption)
			.padding(6)
			.background(Color.red.opacity(0.8), in: Capsule())
			.foregroundStyle(.white)
	}

	private func thumbnail(_ image: UIImage?) -> some View {
		ZStack {
			if let img = image { Image(uiImage: img).resizable().scaledToFill() }
			else { Color.secondary.opacity(0.2).overlay(Image(systemName: "photo").font(.title2)) }
		}
		.frame(width: 64, height: 64)
		.clipShape(RoundedRectangle(cornerRadius: 8))
	}
}

private struct CaptureTipsSheet: View {
	var body: some View {
		NavigationStack {
			List {
				Section("姿态与对齐") {
					Text("保持正脸、水平，十字线居中")
					Text("距离提示显示‘距离合适’时拍摄")
				}
				Section("光线与清晰度") {
					Text("面部均匀、不过曝；画面不模糊")
				}
				Section("三视图要点") {
					Text("左/右侧各转 90°，头不歪")
				}
			}
			.navigationTitle("拍摄要点")
		}
	}
}

private struct VideoPreviewView: UIViewRepresentable {
	let session: AVCaptureSession

	func makeUIView(context: Context) -> PreviewUIView { PreviewUIView() }

	func updateUIView(_ uiView: PreviewUIView, context: Context) {
		uiView.setSession(session)
	}

	final class PreviewUIView: UIView {
		override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
		var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
		func setSession(_ session: AVCaptureSession) {
			previewLayer.session = session
			previewLayer.videoGravity = .resizeAspect
			// 方向与镜像在连接处已设置，这里确保 portrait
			if let connection = previewLayer.connection {
				connection.videoRotationAngle = 90
				if connection.isVideoMirroringSupported {
					connection.automaticallyAdjustsVideoMirroring = false
					connection.isVideoMirrored = true
				}
			}
		}
	}
}

