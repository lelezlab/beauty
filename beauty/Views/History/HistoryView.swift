import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \BeautySession.createdAt, order: .reverse) private var sessions: [BeautySession]
    @State private var loaded = false

    var body: some View {
        List {
            if !sessions.isEmpty {
                Section("SwiftData 会话") {
                    ForEach(sessions, id: \.id) { s in
                        NavigationLink(destination: SessionDetailView(session: s)) {
                            HStack(spacing: 8) {
                                if let ui = s.frontImage { Image(uiImage: ui).resizable().scaledToFill().frame(width: 60, height: 80).clipped().cornerRadius(6) }
                                VStack(alignment: .leading) {
                                    Text(s.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    if let j = s.analysisJSON { Text(j.prefix(30) + "...").font(.caption).foregroundStyle(.secondary) }
                                }
                            }
                        }
                    }
                }
            }
            Section("本地记录(文件)") {
                ForEach(CaptureStore.shared.records) { rec in
                    NavigationLink(destination: HistoryDetailView(rec: rec)) {
                        HStack(spacing: 8) {
                            thumb(path: rec.leftPath)
                            thumb(path: rec.frontPath)
                            thumb(path: rec.rightPath)
                            Spacer()
                            Text(rec.date.formatted(date: .abbreviated, time: .shortened)).font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("历史")
        .onAppear {
            if !loaded { CaptureStore.shared.loadRecords(); loaded = true }
        }
    }

    private func thumb(path: String) -> some View {
        let ui = UIImage(contentsOfFile: path)
        return Image(uiImage: ui ?? UIImage()).resizable().scaledToFill().frame(width: 60, height: 80).clipped().cornerRadius(6)
    }
}

struct HistoryDetailView: View {
    let rec: CaptureStore.CaptureRecord
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                big(path: rec.leftPath)
                big(path: rec.frontPath)
                big(path: rec.rightPath)
            }.padding()
        }
        .navigationTitle("拍摄于 \(rec.date.formatted(date: .abbreviated, time: .shortened))")
    }
    private func big(path: String) -> some View {
        let ui = UIImage(contentsOfFile: path)
        return Image(uiImage: ui ?? UIImage()).resizable().scaledToFit().cornerRadius(10)
    }
}

struct SessionDetailView: View {
    let session: BeautySession
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if let l = session.leftImage { Image(uiImage: l).resizable().scaledToFit().cornerRadius(10) }
                if let f = session.frontImage { Image(uiImage: f).resizable().scaledToFit().cornerRadius(10) }
                if let r = session.rightImage { Image(uiImage: r).resizable().scaledToFit().cornerRadius(10) }
            }
            .padding()
        }
        .navigationTitle("保存于 \(session.createdAt.formatted(date: .abbreviated, time: .shortened))")
    }
}


