import UIKit
import ARKit
import AVFoundation
import SwiftUI

final class FaceCaptureViewController: UIViewController, ARSessionDelegate {
  private let sceneView = ARSCNView(frame: .zero)
  private var overlayHost: UIHostingController<FaceLineOverlay>?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black

    sceneView.frame = view.bounds
    sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    sceneView.session.delegate = self
    view.addSubview(sceneView)

    let host = UIHostingController(rootView: FaceLineOverlay(size: view.bounds.size))
    addChild(host)
    host.view.backgroundColor = .clear
    host.view.frame = view.bounds
    host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(host.view)
    host.didMove(toParent: self)
    overlayHost = host

    if !ARFaceTrackingConfiguration.isSupported {
      // Non-TrueDepth devices: keep only camera preview from other flows; overlay still shows guides
      sceneView.isHidden = true
      host.view.isHidden = false
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if let host = overlayHost {
      host.view.frame = view.bounds
      host.rootView = FaceLineOverlay(size: view.bounds.size)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if ARFaceTrackingConfiguration.isSupported {
      let cfg = ARFaceTrackingConfiguration()
      cfg.isLightEstimationEnabled = true
      sceneView.session.run(cfg, options: [.resetTracking, .removeExistingAnchors])
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sceneView.session.pause()
  }

  func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    // Placeholder: metrics computation is handled elsewhere; AR keeps tracking for stability.
  }
}
