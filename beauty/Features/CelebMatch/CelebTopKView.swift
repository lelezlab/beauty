import SwiftUI

struct CelebTopKView: View {
    @State private var results: [(CelebrityItem, Float)] = []
    @State private var busy = false
    var body: some View {
        List {
            if busy { ProgressView() }
            ForEach(Array(results.enumerated()), id: \.offset) { _, pair in
                HStack { Text(pair.0.name); Spacer(); Text(String(format: "%.3f", pair.1)) }
            }
        }
        .navigationTitle("看看像谁")
        .onAppear { Task { await run() } }
    }
    private func run() async {
        busy = true
        CelebrityIndex.shared.load()
        // Use last captured front frame if available; otherwise synthesize
        let img: UIImage = CaptureStore.shared.frontImage ?? UIImage(systemName: "person")!.withTintColor(.gray)
        let emb = await ArcFaceEmbedder.shared.embed(img).vector
        results = CelebrityIndex.shared.topK(for: emb)
        busy = false
    }
}


