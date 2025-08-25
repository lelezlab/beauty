import SwiftUI

struct CalibrationFlowView: View {
    @ObservedObject private var mgr = CalibrationManager.shared
    @State private var ipdText: String = "63"
    var body: some View {
        Form {
            Section("当前状态") {
                HStack { Text("scale"); Spacer(); Text(String(format: "%.3f mm/px", mgr.state.scaleMMPerPixel ?? 0)) }
                HStack { Text("来源"); Spacer(); Text(mgr.state.source?.rawValue ?? "-") }
            }
            Section("TrueDepth 标定") {
                Button("使用深度数据更新") { mgr.completeDepthCalibration(scale: 0.12) }
            }
            Section("IPD 软标定") {
                HStack { Text("IPD(mm)"); TextField("63", text: $ipdText).keyboardType(.numberPad) }
                Button("保存软标定") { let v = Double(ipdText) ?? 63; mgr.completeIPDCalibration(ipdMM: v) }
            }
            Section("标定卡/棋盘格（占位）") {
                Button("开始标定卡流程") { mgr.beginCardFlow() }
            }
        }
        .navigationTitle("毫米标定")
    }
}


