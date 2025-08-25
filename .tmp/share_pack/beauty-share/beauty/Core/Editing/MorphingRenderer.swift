import Foundation
import CoreImage
import UIKit

enum StylePreset: String, CaseIterable, Identifiable {
	case natural
	case korean
	case japanese
	case western

	var id: String { rawValue }
}

final class MorphingRenderer {
	private let context = CIContext()

	func applyPreset(_ preset: StylePreset, to image: UIImage, landmarks: FacialLandmarksResult) -> UIImage {
		// Placeholder: lightweight filters to stand in for full 3D morphing
		let filter = CIFilter(name: "CIColorControls")!
		switch preset {
		case .natural:
			filter.setValue(1.05, forKey: kCIInputSaturationKey)
			filter.setValue(0.02, forKey: kCIInputBrightnessKey)
			filter.setValue(1.0, forKey: kCIInputContrastKey)
		case .korean:
			filter.setValue(1.1, forKey: kCIInputSaturationKey)
			filter.setValue(0.05, forKey: kCIInputBrightnessKey)
			filter.setValue(1.05, forKey: kCIInputContrastKey)
		case .japanese:
			filter.setValue(0.95, forKey: kCIInputSaturationKey)
			filter.setValue(0.0, forKey: kCIInputBrightnessKey)
			filter.setValue(0.98, forKey: kCIInputContrastKey)
		case .western:
			filter.setValue(1.2, forKey: kCIInputSaturationKey)
			filter.setValue(0.03, forKey: kCIInputBrightnessKey)
			filter.setValue(1.1, forKey: kCIInputContrastKey)
		}
		let ci = CIImage(image: image) ?? CIImage()
		filter.setValue(ci, forKey: kCIInputImageKey)
		guard let out = filter.outputImage,
			  let cg = context.createCGImage(out, from: out.extent) else { return image }
		return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
	}

	func applyManualAdjustments(to image: UIImage, nose: CGFloat, chin: CGFloat, jaw: CGFloat, cheekbone: CGFloat, lips: CGFloat) -> UIImage {
		// Placeholder: simple smoothing and sharpening chain to simulate impact
		let ci = CIImage(image: image) ?? CIImage()
		let smoothAmount = max(0, min(1, (cheekbone + jaw) / 2))
		let sharpenAmount = max(0, min(1, (chin + nose + lips) / 3))
		let smooth = ci.applyingFilter("CINoiseReduction", parameters: ["inputNoiseLevel": smoothAmount * 0.02, "inputSharpness": 0.4])
		let sharp = smooth.applyingFilter("CIUnsharpMask", parameters: [kCIInputIntensityKey: sharpenAmount * 0.7])
		let out = sharp
		let cg = context.createCGImage(out, from: out.extent) ?? image.cgImage
		return UIImage(cgImage: cg!, scale: image.scale, orientation: image.imageOrientation)
	}
}


