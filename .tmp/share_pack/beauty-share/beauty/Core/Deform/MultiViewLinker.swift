import UIKit

public enum MultiViewLinker {
    public static func apply(params: ParametricFace, frames: (front: UIImage, left: UIImage, right: UIImage)) -> (UIImage, UIImage, UIImage) {
        // Placeholder: return original frames; integrate ARFaceAnchor/TPS later
        return (frames.front, frames.left, frames.right)
    }
}


