import UIKit
import ARKit
import AVFoundation

final class FaceCaptureViewController: UIViewController, ARSessionDelegate {
  private let sceneView = ARSCNView(frame: .zero)
  private let overlay = FaceLineOverlay()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    sceneView.frame = view.bounds
    sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    sceneView.session.delegate = self
    view.addSubview(sceneView)
    overlay.frame = view.bounds
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(overlay)

    if !ARFaceTrackingConfiguration.isSupported {
      let fb = FallbackFaceCaptureController()
      fb.view.frame = view.bounds
      addChild(fb); view.addSubview(fb.view); fb.didMove(toParent: self)
      sceneView.isHidden = true
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
    ARFaceGeometryCache.shared.clear()
  }

  func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    guard let face = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
    // Cache a few recent frames for Diagnostics
    ARFaceGeometryCache.shared.update(from: face)
    let geom = face.geometry
    var m = GeometryAnalyzer.analyze(vertices: geom.vertices, transform: face.transform)
    if let rule = RulesStore.shared.byMetric["goode_ratio"],
       let goode = m.goodeRatio, let softMin = rule.soft_min, Double(goode) < softMin {
      m.suggestions.append("增加鼻尖投影 1–2 mm（Goode < \(softMin)）")
    }
    overlay.update(with: m)
  }
}
