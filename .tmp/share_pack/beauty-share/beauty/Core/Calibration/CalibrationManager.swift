import Foundation

enum CalibrationSource: String, Codable { case depth, card, ipd }
struct CalibrationState: Codable { let scaleMMPerPixel: Double?; let source: CalibrationSource?; let timestamp: Date }

final class CalibrationManager: ObservableObject {
    static let shared = CalibrationManager()
    @Published private(set) var state: CalibrationState = CalibrationManager.load()

    private static func load() -> CalibrationState {
        if let data = UserDefaults.standard.data(forKey: "cal_state"), let s = try? JSONDecoder().decode(CalibrationState.self, from: data) { return s }
        return CalibrationState(scaleMMPerPixel: nil, source: nil, timestamp: Date())
    }
    private func persist() { if let d = try? JSONEncoder().encode(state) { UserDefaults.standard.set(d, forKey: "cal_state") } }

    func completeDepthCalibration(scale: Double) {
        state = CalibrationState(scaleMMPerPixel: scale, source: .depth, timestamp: Date())
        persist()
    }
    func completeIPDCalibration(ipdMM: Double) {
        // 简化：假设等效焦距+拍摄距离已在相机层估计；这里仅记录来源
        state = CalibrationState(scaleMMPerPixel: max(0.1, ipdMM/60.0), source: .ipd, timestamp: Date())
        persist()
    }
    func beginCardFlow() {
        // TODO：棋盘格/ArUco 流程；占位标记
    }
}


