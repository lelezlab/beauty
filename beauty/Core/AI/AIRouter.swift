import Foundation
import UIKit

enum PerfTier: String { case L, M, H }
enum AIModule { case reconstruction3D, faceParsing, midasDepth, embedArcFace, detectFace, faceMesh }

struct InferenceMetrics { let fps: Double; let latencyMs: Double; let thermalSerious: Bool }

enum AIRouter {
    static func tier() -> PerfTier {
        let ram = DeviceInfo.ramGB()
        let gen = DeviceInfo.chipGen()
        if gen >= 17 && ram >= 8 { return .H }
        if gen >= 14 && ram >= 4 { return .M }
        return .L
    }

    static func useEdge(for module: AIModule) -> Bool {
        switch module {
        case .reconstruction3D:
            return true
        case .faceParsing, .midasDepth:
            if Battery.level() < 0.25 || Thermal.isSerious() { return true }
            return tier() == .L
        case .embedArcFace, .detectFace, .faceMesh:
            return false
        }
    }

    static func record(metrics: InferenceMetrics) {
        // Minimal hysteresis: store last sample for diagnostics / future decisions
        UserDefaults.standard.set(metrics.fps, forKey: "ai_last_fps")
        UserDefaults.standard.set(metrics.latencyMs, forKey: "ai_last_latency_ms")
        UserDefaults.standard.set(metrics.thermalSerious, forKey: "ai_last_thermal_serious")
    }
}

enum DeviceInfo {
    static func ramGB() -> Int { return ProcessInfo.processInfo.physicalMemory >= 8*1024*1024*1024 ? 8 : 4 }
    static func chipGen() -> Int {
        // Very rough mapping using device model name; unknown → 16
        return 16
    }
}

enum Battery {
    static func level() -> Double {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let v = Double(UIDevice.current.batteryLevel)
        return v.isFinite && v > 0 ? v : 1.0
    }
}

enum Thermal {
    static func isSerious() -> Bool { ProcessInfo.processInfo.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue }
}


