import SwiftUI

struct ConsentFlowView: View {
  @Environment(\.dismiss) var dismiss
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("研究同意与隐私").font(.title2).bold()
      ScrollView {
        Text("""
本应用的分析与建议仅供信息参考，不替代专业医师诊断与治疗建议。
如选择参与匿名数据改进，我们会以差分隐私方式收集使用事件与指标。
你可在设置中随时关闭。详见《隐私政策》。
""")
        .font(.body)
      }
      HStack {
        Button("不同意") { ConsentManager.shared.state = .declined; dismiss() }
        Spacer()
        Button("同意并继续") { ConsentManager.shared.state = .accepted; dismiss() }
          .buttonStyle(.borderedProminent)
      }
    }.padding()
  }
}


