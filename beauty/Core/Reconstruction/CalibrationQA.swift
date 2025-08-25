import Foundation

enum CalibrationStatus: String { case depth, card, ipd, unknown }
struct CalibrationReport { let status: CalibrationStatus; let confidence: Float; let notes:[String] }

enum CalibrationQA {
    static func evaluate(bundle: CaptureBundle, mesh: FaceMesh3D) -> CalibrationReport {
        // TODO: 比对 IPD/三视图一致性/深度可用性
        var notes: [String] = []
        var status: CalibrationStatus = .unknown
        var conf: Float = 0.5
        if let mm = mesh.mmPerPixel, mm > 0 {
            notes.append("scale ok: \(mm) mm/px"); conf = 0.8
        } else if let c = mesh.calibrationMMPerPX, c > 0 {
            notes.append("scale ok: \(c) mm/px"); conf = 0.8
        } else { notes.append("no mm/px, consider recalibration") }
        if bundle.intrinsics != nil { status = .depth; notes.append("intrinsics available") }
        if bundle.ipdNorm != nil { notes.append("ipd norm present") }
        return CalibrationReport(status: status, confidence: conf, notes: notes)
    }
}


