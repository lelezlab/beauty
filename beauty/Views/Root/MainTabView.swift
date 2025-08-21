import SwiftUI
import UIKit

struct MainTabView: View {
	@State private var showCapture = false
	@State private var front: UIImage?
	@State private var left: UIImage?
	@State private var right: UIImage?
    @State private var selectedTab: Int = 0

	var body: some View {
		TabView(selection: $selectedTab) {
			NavigationStack { ResultsDashboardView(metrics: nil, suggestions: []) }
				.tabItem { Label("总览", systemImage: "chart.bar.doc.horizontal") }
				.tag(0)
			NavigationStack { HomeView() }
				.tabItem { Label("首页", systemImage: "sparkles") }
				.tag(1)
			NavigationStack { EffectsGalleryView() }
				.tabItem { Label("效果", systemImage: "wand.and.stars") }
				.tag(2)
			NavigationStack { history }
				.tabItem { Label("历史", systemImage: "clock.arrow.circlepath") }
				.tag(3)
			NavigationStack { settings }
				.tabItem { Label("设置", systemImage: "gear") }
				.tag(4)
		}
	}

	private var home: some View { EmptyView() }

	private var history: some View { Text("本地历史（SwiftData 待接入）").padding() }
	private var settings: some View {
		List {
			NavigationLink("语言 / Language") { LanguageSettingsView() }
			NavigationLink("合规与底线") { ComplianceView().environmentObject(PrivacyManager.shared) }
			NavigationLink("隐私与数据") { PrivacyDataView() }
			Text("登录/订阅/通知设置（占位）")
		}
	}
}

#Preview {
	MainTabView()
}


