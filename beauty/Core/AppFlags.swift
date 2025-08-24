import Foundation

enum AppFlags {
    // 仅用于在 Proof/CI/AI 指标期间抑制重建与大内存任务
    static var isProofRunning: Bool = false
}


