import SwiftUI
import ARKit

public struct FaceCaptureView: UIViewControllerRepresentable {
  public init() {}
  public func makeUIViewController(context: Context) -> FaceCaptureViewController { FaceCaptureViewController() }
  public func updateUIViewController(_ uiViewController: FaceCaptureViewController, context: Context) {}
}
