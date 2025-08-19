import SwiftUI

struct MainTabView: View {
	@State private var showCapture = false
	@State private var front: UIImage?
	@State private var left: UIImage?
	@State private var right: UIImage?

	var body: some View {
		TabView {
			NavigationStack { home }
				.tabItem { Label("首页", systemImage: "sparkles") }
			NavigationStack { history }
				.tabItem { Label("历史", systemImage: "clock.arrow.circlepath") }
			NavigationStack { settings }
				.tabItem { Label("设置", systemImage: "gear") }
		}
	}

	private var home: some View {
		VStack(spacing: 16) {
			Text("SoYoung 面部美学模拟").font(.largeTitle).bold()
			Text("引导拍摄、AI 关键点、三庭五眼与一键模板")
			Button("开始拍摄") { showCapture = true }
				.buttonStyle(.borderedProminent)
				.sheet(isPresented: $showCapture) {
					GuidedCaptureView { f, l, r in
						front = f; left = l; right = r; showCapture = false
					}
				}
			if let front {
				NavigationLink("查看分析") { AnalysisView(front: front) }
			}
			Spacer()
		}
		.padding()
	}

	private var history: some View { Text("本地历史（SwiftData 待接入）").padding() }
	private var settings: some View { Text("登录/订阅/通知设置（占位）").padding() }
}

#Preview {
	MainTabView()
}


