import SwiftUI

enum ScreenshotDevice {
  case iPhone65, iPhone67
  var size: CGSize {
    switch self { case .iPhone65: return CGSize(width:1242, height:2688)
                  case .iPhone67: return CGSize(width:1290, height:2796) }
  }
}

struct ScreenshotRunner {
  static func render<V:View>(_ view: V, device: ScreenshotDevice, locale: Locale = .current) -> CGImage? {
    let controller = UIHostingController(rootView: view.environment(\.locale, locale))
    controller.view.bounds = CGRect(origin:.zero, size: device.size)
    let renderer = UIGraphicsImageRenderer(size: device.size)
    return renderer.image { _ in controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true) }.cgImage
  }
}


