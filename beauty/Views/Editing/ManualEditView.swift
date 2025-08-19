import SwiftUI

struct ManualEditView: View {
	let original: UIImage
	let landmarks: FacialLandmarksResult?
	@State private var nose: CGFloat = 0.5
	@State private var chin: CGFloat = 0.5
	@State private var jaw: CGFloat = 0.5
	@State private var cheek: CGFloat = 0.5
	@State private var lips: CGFloat = 0.5
	private let renderer = MorphingRenderer()

	var body: some View {
		VStack(spacing: 12) {
			HStack {
				Image(uiImage: original).resizable().scaledToFit()
				Image(uiImage: rendered).resizable().scaledToFit()
			}
			.frame(height: 280)
			Group {
				slider("鼻", $nose)
				slider("下巴", $chin)
				slider("颌线", $jaw)
				slider("颧", $cheek)
				slider("唇", $lips)
			}
			.padding(.horizontal)
		}
		.navigationTitle("手动编辑")
	}

	private var rendered: UIImage {
		renderer.applyManualAdjustments(to: original, nose: nose, chin: chin, jaw: jaw, cheekbone: cheek, lips: lips)
	}

	@ViewBuilder private func slider(_ title: String, _ binding: Binding<CGFloat>) -> some View {
		HStack { Text(title).frame(width: 60, alignment: .leading); Slider(value: binding, in: 0...1) }
	}
}


