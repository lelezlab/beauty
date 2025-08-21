import UIKit

final class CaptureStore {
    static let shared = CaptureStore()
    private init() {}

    var frontImage: UIImage?
    var frontLandmarks: FacialLandmarksResult?
}


