import SwiftUI
import UIKit

struct MainTabView: View {
	@State private var showCapture = false
	@State private var front: UIImage?
	@State private var left: UIImage?
	@State private var right: UIImage?

	var body: some View {
		TabView {
			NavigationStack { HomeView() }
				.tabItem { Label("首页", systemImage: "sparkles") }
			NavigationStack { history }
				.tabItem { Label("历史", systemImage: "clock.arrow.circlepath") }
			NavigationStack { settings }
				.tabItem { Label("设置", systemImage: "gear") }
		}
	}

	private var home: some View { EmptyView() }

	private var history: some View { Text("本地历史（SwiftData 待接入）").padding() }
	private var settings: some View {
		List {
			NavigationLink("语言 / Language") { LanguageSettingsView() }
			Text("登录/订阅/通知设置（占位）")
		}
	}
}

#Preview {
	MainTabView()
}


