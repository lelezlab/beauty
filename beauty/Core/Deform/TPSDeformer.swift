import UIKit

public struct Anchor { public let src: CGPoint; public let dst: CGPoint }

public enum TPSDeformer {
    // Minimal placeholder: returns original image. TODO: implement thin-plate spline warp.
    public static func warp(image: UIImage, anchors: [Anchor]) -> UIImage { image }
}


