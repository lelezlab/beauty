import SwiftUI

struct GuidedTipsOverlay: View {
  @Binding var visible: Bool
  var body: some View {
    if visible {
      VStack(alignment:.leading, spacing: 8) {
        Label("保持手机与面部平齐，光线均匀", systemImage: "sun.max")
        Label("按提示缓慢转头至左右约 30°", systemImage: "head.profile")
        Label("避免头发遮挡额头与下颌线", systemImage: "person.fill.questionmark")
      }
      .padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
      .padding()
      .transition(.move(edge:.top).combined(with:.opacity))
    }
  }
}


