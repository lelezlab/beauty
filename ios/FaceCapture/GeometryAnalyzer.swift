import ARKit
import simd

struct AestheticMetrics {
  var nasolabialAngle: Float?
  var nasofrontalAngle: Float?
  var cervicomentalAngle: Float?
  var goodeRatio: Float?
  var suggestions: [String] = []
}

enum GeometryAnalyzer {
  static func analyze(vertices: [SIMD3<Float>], transform: simd_float4x4) -> AestheticMetrics {
    var m = AestheticMetrics()
    // 占位：真实实现需映射网格索引到解剖学锚点或拟合 FLAME
    m.nasolabialAngle = 102
    m.nasofrontalAngle = 125
    m.cervicomentalAngle = 95
    m.goodeRatio = 0.57
    // 若无在线规则，给出默认提示
    if RulesStore.shared.byMetric.isEmpty, let goode = m.goodeRatio, goode < 0.55 {
      m.suggestions.append("（默认）增加鼻尖投影 1–2 mm")
    }
    return m
  }
}
