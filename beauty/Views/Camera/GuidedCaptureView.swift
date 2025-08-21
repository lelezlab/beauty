import SwiftUI
import UIKit
import AVFoundation

struct GuidedCaptureView: View {
	@StateObject private var camera = CameraSession()
	@State private var front: UIImage?
	@State private var left: UIImage?
	@State private var right: UIImage?
	@State private var step: Int = 0
	@State private var requireQualityPass: Bool = true
	var onFinished: (UIImage, UIImage, UIImage) -> Void

	var body: some View {
		VStack(spacing: 12) {
			ZStack(alignment: .topTrailing) {
				CameraPreview(sampleBuffer: $camera.sampleBuffer)
					.overlay { guideOverlay }
					.overlay { if FeatureFlags.goldenGuidesEnabled { GoldenGuidesOverlay().allowsHitTesting(false) } }
				.overlay(alignment: .top) {
					HStack { levelIndicator; qualityBadges }.padding(8)
				}
			}
			Text(instructionText)
				.font(.headline)
				.padding(.top, 4)
			Toggle("必须通过质检后才能拍照", isOn: $requireQualityPass)
				.toggleStyle(.switch)
				.padding(.bottom, 2)
			HStack {
				Button("拍照") { capture() }
					.buttonStyle(.borderedProminent)
					.disabled(!canCapture)
				Button("重拍") { resetCurrent() }.disabled(currentImage == nil)
			}
			HStack {
				thumbnail(front)
				thumbnail(left)
				thumbnail(right)
			}
			.padding(.top, 8)
			if front != nil && left != nil && right != nil {
				Button("完成") {
					onFinished(front!, left!, right!)
				}
				.buttonStyle(.borderedProminent)
				.padding(.top, 6)
			}
		}
	}

	private var instructionText: String {
		switch step {
		case 0: return "正面视图：保持水平、光线充足"
		case 1: return "左侧视图：头部左转 90°"
		default: return "右侧视图：头部右转 90°"
		}
	}

	private var canCapture: Bool { !requireQualityPass || (!camera.exposureTooLow && !camera.isBlurry) }

	private var currentImage: UIImage? {
		switch step { case 0: return front; case 1: return left; default: return right }
	}

	private func capture() { camera.capturePhoto { image in
		guard let image else { return }
		switch step { case 0: front = image; case 1: left = image; default: right = image }
		step = min(step + 1, 2)
	} }

	private func resetCurrent() { switch step { case 0: front = nil; case 1: left = nil; default: right = nil } }

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

private struct CameraPreview: UIViewRepresentable {
	@Binding var sampleBuffer: CMSampleBuffer?

	func makeUIView(context: Context) -> UIImageView { let v = UIImageView(); v.contentMode = .scaleAspectFit; v.backgroundColor = .black; return v }
	func updateUIView(_ uiView: UIImageView, context: Context) {
		guard let buffer = sampleBuffer, let image = imageFrom(buffer) else { return }
		uiView.image = image
	}
	private func imageFrom(_ buffer: CMSampleBuffer) -> UIImage? {
		guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return nil }
		let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
		let context = CIContext(options: nil)
		guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
		return UIImage(cgImage: cgImage)
	}
}


