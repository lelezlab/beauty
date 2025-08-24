import AVFoundation
import CoreMotion
import UIKit
import UniformTypeIdentifiers
import Vision

final class CameraSession: NSObject, ObservableObject {
	@Published var sampleBuffer: CMSampleBuffer?
	@Published var exposureTooLow: Bool = false
	@Published var isBlurry: Bool = false
	@Published var levelDegrees: Double = 0
	@Published var aeLocked: Bool = false
	@Published var awbLocked: Bool = false
	@Published var focalEqMM: Double = 50.0
	@Published var fieldOfViewDegrees: Double = 60.0
	@Published var faceCoverageRatio: Double = 0.0 // 人脸高度 / 画面高度
	@Published var distanceBucket: Int = 3 // 1..5

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
	private var distanceTimer: DispatchSourceTimer?

	override init() {
		super.init()
		configure()
		startMotionUpdates()
		startDistanceUpdates()
	}

	private func configure() {
		sessionQueue.async {
			self.captureSession.beginConfiguration()
			self.captureSession.sessionPreset = .high
			guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ??
					AVCaptureDevice.default(for: .video) else { return }
			guard let input = try? AVCaptureDeviceInput(device: device) else { return }
			if self.captureSession.canAddInput(input) { self.captureSession.addInput(input) }
			// 数据输出（用于质检/抓拍），设置像素格式
			self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
			self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
			self.videoOutput.alwaysDiscardsLateVideoFrames = true
			if self.captureSession.canAddOutput(self.videoOutput) { self.captureSession.addOutput(self.videoOutput) }

			// 连接方向 / 稳定 / 前置镜像
			if let connection = self.videoOutput.connection(with: .video) {
				connection.videoRotationAngle = 90
				if connection.isVideoMirroringSupported {
					connection.automaticallyAdjustsVideoMirroring = false
					connection.isVideoMirrored = true
				}
				if connection.isVideoStabilizationSupported { connection.preferredVideoStabilizationMode = .standard }
			}

			// 相机设备参数：平滑对焦、连续 AE/AWB，避免频繁区域变更；尽量稳定帧率
			if (try? device.lockForConfiguration()) != nil {
				device.isSubjectAreaChangeMonitoringEnabled = false
				if device.isSmoothAutoFocusSupported { device.isSmoothAutoFocusEnabled = true }
				if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
				if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }
				if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) { device.whiteBalanceMode = .continuousAutoWhiteBalance }
				// 将帧率稳定在 30fps（在支持范围内）
				if let range = device.activeFormat.videoSupportedFrameRateRanges.first {
					let target: Double = min(30.0, range.maxFrameRate)
					let time = CMTime(value: 1, timescale: CMTimeScale(target))
					device.activeVideoMinFrameDuration = time
					device.activeVideoMaxFrameDuration = time
				}
				device.unlockForConfiguration()
			}
			self.captureSession.commitConfiguration()
			// 读取设备参数（近似）
			self.readDeviceParameters(device)
			self.captureSession.startRunning()
		}
	}

	private func readDeviceParameters(_ device: AVCaptureDevice) {
		let fov = Double(device.activeFormat.videoFieldOfView)
		// 35mm 等效焦距近似：f ≈ 43.27 / (2*tan(FOV/2)) （对角 FOV）
		let rad = fov * .pi / 180.0
		let denom = 2.0 * tan(rad/2.0)
		let focal: Double? = denom > 0.0001 ? (43.27 / denom) : nil
		let ae = (device.exposureMode == .locked)
		let awb = (device.whiteBalanceMode == .locked)
		DispatchQueue.main.async { [weak self] in
			self?.fieldOfViewDegrees = fov
			if let focal = focal { self?.focalEqMM = focal }
			self?.aeLocked = ae
			self?.awbLocked = awb
		}
	}

	private func startDistanceUpdates() {
		let timer = DispatchSource.makeTimerSource(queue: sessionQueue)
		self.distanceTimer = timer
		timer.schedule(deadline: .now() + 0.5, repeating: 0.8)
		timer.setEventHandler { [weak self] in
			guard let self, let buffer = self.sampleBuffer, let pixel = CMSampleBufferGetImageBuffer(buffer) else { return }
			let handler = VNImageRequestHandler(cvPixelBuffer: pixel, orientation: .up, options: [:])
			let req = VNDetectFaceRectanglesRequest()
			try? handler.perform([req])
			if let first = (req.results?.first as? VNFaceObservation) {
				let h = Double(first.boundingBox.height) // 已归一化
				let ratio = max(0.0, min(1.0, h))
				let bucket = Self.mapCoverageToBucket(ratio)
				DispatchQueue.main.async { [weak self] in self?.faceCoverageRatio = ratio; self?.distanceBucket = bucket }
			}
		}
		timer.resume()
	}

	private static func mapCoverageToBucket(_ ratio: Double) -> Int {
		// 简易阈值：小于0.18太远(1)，0.18..0.28(2)，0.28..0.40(3，推荐)，0.40..0.55(4)，>0.55太近(5)
		switch ratio {
		case ..<0.18: return 1
		case ..<0.28: return 2
		case ..<0.40: return 3
		case ..<0.55: return 4
		default: return 5
		}
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
		return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .upMirrored)
	}
}

extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		DispatchQueue.main.async { [weak self] in self?.sampleBuffer = sampleBuffer }
		self.estimateQuality(from: sampleBuffer)
		self.pollDeviceParams()
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

private extension CameraSession {
    func pollDeviceParams() {
        guard let device = (captureSession.inputs.first as? AVCaptureDeviceInput)?.device else { return }
        let ae = (device.exposureMode == .locked)
        let awb = (device.whiteBalanceMode == .locked)
        let fov = Double(device.activeFormat.videoFieldOfView)
        let rad = fov * .pi / 180.0
        let denom = 2.0 * tan(rad/2.0)
        let focal: Double? = denom > 0.0001 ? (43.27 / denom) : nil
        DispatchQueue.main.async { [weak self] in
            self?.aeLocked = ae
            self?.awbLocked = awb
            self?.fieldOfViewDegrees = fov
            if let focal = focal { self?.focalEqMM = focal }
        }
    }
}

