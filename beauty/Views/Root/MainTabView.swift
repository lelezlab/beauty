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
            NavigationStack { CaptureModeSwitcher() }
                .tabItem { Label("面诊", systemImage: "camera.viewfinder") }
                .tag(6)
			NavigationStack { AssistantTabView() }
				.tabItem { Label("助手", systemImage: "message.badge.waveform") }
				.tag(5)
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

	private var history: some View { HistoryView() }
	private var settings: some View {
		List {
			Section("Proof Pack") {
				NavigationLink("Generate Proof Pack") { DeveloperMenuView() }
			}
			Section("AI / 相似度") {
				NavigationLink("术后像谁（离线/远端）") { CelebTopKView() }
			}
			NavigationLink("语言 / Language") { LanguageSettingsView() }
			NavigationLink("合规与底线") { ComplianceView().environmentObject(PrivacyManager.shared) }
			NavigationLink("隐私与数据") { PrivacyDataView() }
			NavigationLink("隐私中心") { PrivacyCenterView() }
			NavigationLink("开发者参数（黄金法则映射）") { DevTuningView() }
			NavigationLink("Developer (Celeb)") { DeveloperDebugView() }
			NavigationLink("Diagnostics") { DiagnosticsView() }
			NavigationLink("About") { AboutView() }
			NavigationLink("知识库（远程）") { KnowledgeBrowserView() }
			NavigationLink("BDD 自评") { BDDSelfAssessmentView() }
			Text("登录/订阅/通知设置（占位）")
		}
		.onTapGesture(count: 5) { DeveloperVisibility.showDeveloper.toggle() }
	}
}

private struct CaptureFlowView: View {
    @State private var front: UIImage?
    @State private var left: UIImage?
    @State private var right: UIImage?
    @State private var goAnalysis: Bool = false
    var body: some View {
        VStack {
            GuidedCaptureView { f, l, r in
                front = f; left = l; right = r
                goAnalysis = true
            }
            .navigationDestination(isPresented: $goAnalysis) {
                AnalysisView(front: front ?? UIImage())
            }
        }
    }
}

private struct CaptureModeSwitcher: View {
    @State private var useVideo: Bool = true
    @State private var front: UIImage?
    @State private var left: UIImage?
    @State private var right: UIImage?
    @State private var goAnalysis: Bool = false
    @State private var go3DPreview: Bool = false
    var body: some View {
        VStack {
            HStack {
                Picker("模式", selection: $useVideo) {
                    Text("动态").tag(true)
                    Text("拍照").tag(false)
                }
                .pickerStyle(.segmented)
                Spacer()
                NavigationLink(destination: CalibrationFlowView()) { CalibrationBadge() }
            }
            .padding(.horizontal)
            if useVideo {
                FaceVideoCaptureView { f, l, r in
                    front = f; left = l; right = r; goAnalysis = false; go3DPreview = true
                    // 完成三帧后触发 3D 重建（占位后台）；若 QC 不足则优雅降级
                    let qcOK = (ConfidenceEstimator.score(from: BeautyTelemetryService.shared.lastQC ?? BTCaptureQC(blurScore: 0.3, exposureMean: 0.6, faceCoverage: 0.5, yaw: nil, pitch: nil, roll: nil, focalEq: nil, distanceBucket: 3, aeLocked: nil, awbLocked: nil, alignScore: 0.6))) >= 0.5
                    if qcOK {
                        Task { _ = await ReconstructionOrchestrator.shared.reconstructAuto() }
                    }
                }
            } else {
                GuidedCaptureView { f, l, r in
                    front = f; left = l; right = r; goAnalysis = false; go3DPreview = true
                    let qcOK = (ConfidenceEstimator.score(from: BeautyTelemetryService.shared.lastQC ?? BTCaptureQC(blurScore: 0.3, exposureMean: 0.6, faceCoverage: 0.5, yaw: nil, pitch: nil, roll: nil, focalEq: nil, distanceBucket: 3, aeLocked: nil, awbLocked: nil, alignScore: 0.6))) >= 0.5
                    if qcOK {
                        Task { _ = await ReconstructionOrchestrator.shared.reconstructAuto() }
                    }
                }
            }
        }
        .navigationDestination(isPresented: $goAnalysis) { AnalysisView(front: front ?? UIImage()) }
        .navigationDestination(isPresented: $go3DPreview) { Face3DPreviewView() }
        .navigationTitle("面诊")
    }
}

#Preview {
	MainTabView()
}


