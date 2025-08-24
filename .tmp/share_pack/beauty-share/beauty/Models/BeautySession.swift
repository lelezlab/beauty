import Foundation
import SwiftData
import UIKit

@Model
final class BeautySession {
	@Attribute(.unique) var id: String
	var createdAt: Date
	var frontImageData: Data?
	var leftImageData: Data?
	var rightImageData: Data?
	var analysisJSON: String?
	var editedImageData: Data?

	init(id: String = UUID().uuidString,
		 createdAt: Date = Date(),
		 frontImage: UIImage? = nil,
		 leftImage: UIImage? = nil,
		 rightImage: UIImage? = nil) {
		self.id = id
		self.createdAt = createdAt
		self.frontImageData = frontImage?.jpegData(compressionQuality: 0.9)
		self.leftImageData = leftImage?.jpegData(compressionQuality: 0.9)
		self.rightImageData = rightImage?.jpegData(compressionQuality: 0.9)
	}

	var frontImage: UIImage? { frontImageData.flatMap { UIImage(data: $0) } }
	var leftImage: UIImage? { leftImageData.flatMap { UIImage(data: $0) } }
	var rightImage: UIImage? { rightImageData.flatMap { UIImage(data: $0) } }
	var editedImage: UIImage? { editedImageData.flatMap { UIImage(data: $0) } }
}


