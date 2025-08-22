import SwiftUI

struct HomeView: View {
    @StateObject private var region = RegionManager()
    @State private var searchText: String = ""
    @State private var showCapture: Bool = false
    @State private var showCart: Bool = false
    @State private var showAssistant: Bool = false

    @State private var config: HomeConfig = HomeConfigLoader.loadFromBundle() ?? .default

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    topBar
                    banner(config.banners)
                    categoryGrid(config.categories)
                    featuredCards(config.featured)
                    quickActions(config.quickActions)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .task { region.request(); await tryFetchRemote() }
        }
    }

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button { region.request() } label: {
                    Label(region.displayName, systemImage: "location")
                        .font(.headline)
                }.buttonStyle(.plain)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    TextField("项目/机构/医生/商品", text: $searchText)
                }
                .padding(10)
                .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                Button { showAssistant = true } label: {
                    Text("AI 助手")
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.15), in: Capsule())
                }

                Button { showCart = true } label: {
                    Image(systemName: "cart")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showAssistant) { AssistantTabView() }
        .sheet(isPresented: $showCart) { PlaceholderListView(title: "购物车") }
    }

    private func tryFetchRemote() async {
        var url = RemoteConfigService.defaultURL
        if let cc = region.countryCode {
            url = URL(string: url.absoluteString.replacingOccurrences(of: "home_data.json", with: "home_data.\(cc).json")) ?? url
        }
        if let remote = await RemoteConfigService.fetchHomeConfig(from: url) {
            config = remote
        }
    }

    private func banner(_ data: [BannerItem]) -> some View {
        TabView {
            ForEach(Array(data.enumerated()), id: \.offset) { idx, item in
                ZStack {
                    LinearGradient(colors: [.blue.opacity(0.2), .pink.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.title)
                            .font(.title2).bold()
                        Text(item.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(height: 160)
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }

    private func categoryGrid(_ items: [CategoryItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                ForEach(items) { item in
                    VStack(spacing: 8) {
                        Image(systemName: item.symbol)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(Color.secondary.opacity(0.12), in: Circle())
                        Text(item.title).font(.caption)
                    }
                }
            }
        }
    }

    private func featuredCards(_ items: [FeaturedItem]) -> some View {
        VStack(spacing: 12) {
            ForEach(0..<items.count/2 + items.count%2, id: \.self) { row in
                HStack(spacing: 12) {
                    let i = row*2
                    FeaturedCard(title: items[i].title, subtitle: items[i].subtitle, symbol: items[i].symbol)
                        .onTapGesture { if items[i].symbol == "camera" { showCapture = true } }
                    if i+1 < items.count {
                        FeaturedCard(title: items[i+1].title, subtitle: items[i+1].subtitle, symbol: items[i+1].symbol)
                            .onTapGesture { if items[i+1].symbol == "camera" { showCapture = true } }
                    } else {
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .sheet(isPresented: $showCapture) { CaptureLauncherView() }
    }

    private func quickActions(_ items: [QuickActionItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快捷功能").font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(items) { item in
                    QuickActionButton(title: item.title, symbol: item.symbol)
                }
            }
        }
    }
}

private struct FeaturedCard: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: symbol).font(.title2)
                Text(title).font(.headline)
            }
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct QuickActionButton: View {
    let title: String
    let symbol: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol).font(.title2)
                .frame(width: 48, height: 48)
                .background(Color.secondary.opacity(0.12), in: Circle())
            Text(title).font(.footnote)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}

// removed local CategoryItem (now provided by Core/Config/HomeConfig.swift)

private struct CaptureLauncherView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var front: UIImage? = nil
    @State private var left: UIImage? = nil
    @State private var right: UIImage? = nil
    @State private var showAnalysis: Bool = false

    var body: some View {
        NavigationStack {
            if showAnalysis, let f = front {
                AnalysisView(front: f)
                    .navigationTitle("分析")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                GuidedCaptureView { f, l, r in
                    front = f; left = l; right = r
                    showAnalysis = true
                }
                .navigationTitle("引导拍摄")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct AssistantTabView: View {
    @State private var input: String = ""
    @State private var messages: [String] = ["你好，我是你的美学助手。请输入需求或拍摄分析后点此提问。"]
    var body: some View {
        VStack(spacing: 0) {
            List(messages, id: \.self) { m in Text(m) }
            HStack(spacing: 8) {
                TextField("向助手提问，例如：我的鼻唇角如何优化？", text: $input)
                    .textFieldStyle(.roundedBorder)
                Button("发送") {
                    guard !input.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    messages.append("你：" + input)
                    // 简单占位：根据关键词给出知识链接
                    let reply = AssistantEngine.generateReply(for: input)
                    messages.append(reply)
                    input = ""
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(10)
            .background(.ultraThinMaterial)
        }
        .navigationTitle("AI 助手")
    }
}

enum AssistantEngine {
    static func generateReply(for query: String) -> String {
        let q = query.lowercased()
        if q.contains("鼻") || q.contains("naso") {
            return "助手：你可以查看知识《鼻唇角》与《鼻背直化》。建议先完成三视图拍摄以获得更精确建议。"
        }
        if q.contains("下巴") || q.contains("chin") {
            return "助手：针对下巴投影，可参考《颏点后缩》知识条目，并在效果中调整 chin_projection。"
        }
        return "助手：已记录你的问题。当前版本提供知识检索与参数指引，后续将联动你的分析数据与术式建议。"
    }
}

private struct PlaceholderListView: View {
    let title: String
    var body: some View {
        NavigationStack {
            List(0..<10, id: \.self) { idx in
                HStack {
                    RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.2)).frame(width: 60, height: 60)
                    VStack(alignment: .leading) {
                        Text("占位项 #\(idx+1)").bold()
                        Text("这里是 \(title) 列表占位").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(title)
        }
    }
}


