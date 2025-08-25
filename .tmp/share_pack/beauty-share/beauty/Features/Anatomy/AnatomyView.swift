import SwiftUI

struct AnatomyView: View {
    let targets: [String]
    var body: some View {
        let items = AnatomyStore.byIds(targets)
        List(items) { it in
            VStack(alignment: .leading, spacing: 6) {
                Text(it.name).font(.headline)
                Text(it.summary).font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("解剖结构")
    }
}


