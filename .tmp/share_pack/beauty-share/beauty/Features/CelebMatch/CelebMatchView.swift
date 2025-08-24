import SwiftUI

struct CelebMatchView: View {
    @State private var image: UIImage? = nil
    @State private var folderPath: String = ""
    @State private var matches: [TopMatch] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text("明星图库文件夹路径"); TextField("/path/to/zip/unzipped", text: $folderPath).textInputAutocapitalization(.never) }
            Button("构建索引并匹配 Top3") { buildAndMatch() }.buttonStyle(.borderedProminent)
            if matches.isEmpty { Text("提示：仅离线演示，需用户自带授权图库。不存储不上传。").font(.footnote).foregroundStyle(.secondary) }
            ForEach(matches) { m in
                HStack(alignment: .center, spacing: 12) {
                    if let t = m.thumb { Image(uiImage: t).resizable().frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 8)) }
                    VStack(alignment: .leading) {
                        Text(m.name).bold()
                        Text(String(format: "相似度 %.0f%%", m.score*100)).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Text("法律提示：相似度为算法估算，图库需具备授权；本功能仅在本机离线运行，不做身份识别。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("术后像谁（离线）")
    }

    private func buildAndMatch() {
        let url = URL(fileURLWithPath: folderPath)
        let builder = EmbedIndexBuilder(model: StubEmbeddingModel())
        let (entries, vectors) = builder.build(from: url)
        let matcher = CelebMatcher(entries: entries, vectors: vectors, model: StubEmbeddingModel())
        let img: UIImage = image ?? synthesizedSample()
        matches = matcher.topK(for: img, k: 3)
    }

    private func synthesizedSample() -> UIImage {
        let size = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.systemPink.setFill(); ctx.fill(CGRect(origin: .zero, size: size))
            ("Sample" as NSString).draw(at: CGPoint(x: 90, y: 120), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 28), .foregroundColor: UIColor.white])
        }
    }
}


