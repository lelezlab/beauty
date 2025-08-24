import UIKit

final class FaceLineOverlay: UIView {
  private var metrics = AestheticMetrics()
  func update(with m: AestheticMetrics) { metrics = m; DispatchQueue.main.async { self.setNeedsDisplay() } }

  override func draw(_ rect: CGRect) {
    guard let ctx = UIGraphicsGetCurrentContext() else { return }
    let w = rect.width, h = rect.height
    UIColor.systemGreen.setStroke(); ctx.setLineWidth(2)
    for i in 1...2 { let y = CGFloat(i)*h/3.0; ctx.move(to: .init(x: 0, y: y)); ctx.addLine(to: .init(x: w, y: y)) }
    ctx.move(to: .init(x: w/2, y: 0)); ctx.addLine(to: .init(x: w/2, y: h)); ctx.strokePath()
    let text = metrics.suggestions.joined(separator: "\n")
    if !text.isEmpty {
      let ps = NSMutableParagraphStyle(); ps.alignment = .left
      let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .footnote), .foregroundColor: UIColor.systemYellow, .paragraphStyle: ps]
      text.draw(with: CGRect(x: 12, y: 12, width: w-24, height: 200), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
    }
  }
}
