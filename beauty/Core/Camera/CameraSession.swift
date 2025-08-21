import AVFoundation
import CoreMotion
import UIKit
import UniformTypeIdentifiers

final class CameraSession: NSObject, ObservableObject {
	@Published var sampleBuffer: CMSampleBuffer?
	@Published var exposureTooLow: Bool = false
	@Published var isBlurry: Bool = false
	@Published var levelDegrees: Double = 0
	@Published var aeLocked: Bool = false
	@Published var awbLocked: Bool = false
	@Published var focalEqMM: Double = 50.0
	@Published var fieldOfViewDegrees: Double = 60.0

	// 质量门控阈值（可调）
	let minLuma: Float = 0.25
	let minEdgeScore: Float = 0.08

	let captureSession = AVCaptureSession()
	private let sessionQueue = DispatchQueue(label: "camera.session.queue")
	private let motionManager = CMMotionManager()
	private let motionQueue: OperationQueue = {
		let q = OperationQueue()
		q.name = "camera.motion.queue"
		q.qualityOfService = .userInitiated
		return q
	}()
	private let videoOutput = AVCaptureVideoDataOutput()
    private let ciContext = CIContext(options: nil)

	override init() {
		super.init()
		configure()
		startMotionUpdates()
	}

	private func configure() {
		sessionQueue.async {
			self.captureSession.beginConfiguration()
			self.captureSession.sessionPreset = .high
			guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ??
					AVCaptureDevice.default(for: .video) else { return }
			guard let input = try? AVCaptureDeviceInput(device: device) else { return }
			if self.captureSession.canAddInput(input) { self.captureSession.addInput(input) }
			self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
			self.videoOutput.alwaysDiscardsLateVideoFrames = true
			if self.captureSession.canAddOutput(self.videoOutput) { self.captureSession.addOutput(self.videoOutput) }
			self.captureSession.commitConfiguration()
			// 读取设备参数（近似）
			self.readDeviceParameters(device)
			self.captureSession.startRunning()
		}
	}

	private func readDeviceParameters(_ device: AVCaptureDevice) {
		let fov = Double(device.activeFormat.videoFieldOfView)
		self.fieldOfViewDegrees = fov
		// 35mm 等效焦距近似：f ≈ 43.27 / (2*tan(FOV/2)) （对角 FOV）
		let rad = fov * .pi / 180.0
		let denom = 2.0 * tan(rad/2.0)
		if denom > 0.0001 { self.focalEqMM = 43.27 / denom }
		self.aeLocked = (device.exposureMode == .locked)
		self.awbLocked = (device.whiteBalanceMode == .locked)
	}

	private func startMotionUpdates() {
		motionManager.deviceMotionUpdateInterval = 0.1
		motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, _ in
			guard let self, let motion else { return }
			let roll = motion.attitude.roll * 180.0 / .pi
			DispatchQueue.main.async { self.levelDegrees = roll }
		}
	}

	func capturePhoto(completion: @escaping (UIImage?) -> Void) {
		sessionQueue.async { [weak self] in
			guard let self, let buffer = self.sampleBuffer else { DispatchQueue.main.async { completion(nil) }; return }
			guard let image = Self.imageFromSampleBuffer(buffer: buffer) else { DispatchQueue.main.async { completion(nil) }; return }
			DispatchQueue.main.async { completion(image) }
		}
	}

	private static func imageFromSampleBuffer(buffer: CMSampleBuffer) -> UIImage? {
		guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return nil }
		let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
		let context = CIContext(options: nil)
		guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
		return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .leftMirrored)
	}
}

extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		DispatchQueue.main.async { [weak self] in self?.sampleBuffer = sampleBuffer }
		self.estimateQuality(from: sampleBuffer)
	}

	private func estimateQuality(from sampleBuffer: CMSampleBuffer) {
		guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
		let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

		// Average luminance via CIAreaAverage
		let extent = ciImage.extent
		let avgFilter = CIFilter(name: "CIAreaAverage")!
		avgFilter.setValue(ciImage, forKey: kCIInputImageKey)
		avgFilter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
		var luma: Float = 0.5
		if let output = avgFilter.outputImage, let outCG = ciContext.createCGImage(output, from: CGRect(x: 0, y: 0, width: 1, height: 1)) {
			let data = CFDataCreateMutable(nil, 0)
			let dest = CGImageDestinationCreateWithData(data!, UTType.png.identifier as CFString, 1, nil)
			if let dest = dest {
				CGImageDestinationAddImage(dest, outCG, nil)
				CGImageDestinationFinalize(dest)
				if let bytes = CFDataGetBytePtr(data!) {
					let r = Float(bytes[33]) / 255.0
					let g = Float(bytes[34]) / 255.0
					let b = Float(bytes[35]) / 255.0
					luma = 0.2126*r + 0.7152*g + 0.0722*b
				}
			}
		}

		// Edge magnitude as blur proxy
		var blurScore: Float = 0.5
		let edges = CIFilter(name: "CIEdges")!
		edges.setValue(ciImage, forKey: kCIInputImageKey)
		edges.setValue(1.0, forKey: kCIInputIntensityKey)
		if let edgeOut = edges.outputImage {
			let avg = CIFilter(name: "CIAreaAverage")!
			avg.setValue(edgeOut, forKey: kCIInputImageKey)
			avg.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
			if let out = avg.outputImage, let cg = ciContext.createCGImage(out, from: CGRect(x: 0, y: 0, width: 1, height: 1)) {
				let data = CFDataCreateMutable(nil, 0)
				let dest = CGImageDestinationCreateWithData(data!, UTType.png.identifier as CFString, 1, nil)
				if let dest = dest {
					CGImageDestinationAddImage(dest, cg, nil)
					CGImageDestinationFinalize(dest)
					if let bytes = CFDataGetBytePtr(data!) {
						let r = Float(bytes[33]) / 255.0
						let g = Float(bytes[34]) / 255.0
						let b = Float(bytes[35]) / 255.0
						blurScore = (r + g + b) / 3.0
					}
				}
			}
		}

		DispatchQueue.main.async { [weak self] in
			self?.exposureTooLow = luma < (self?.minLuma ?? 0.25)
			self?.isBlurry = blurScore < (self?.minEdgeScore ?? 0.08)
		}
	}
}

