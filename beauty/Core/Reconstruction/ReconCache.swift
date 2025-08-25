import Foundation

enum ReconCache {
    static func baseURL() -> URL {
        let appSup = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSup.appendingPathComponent("ReconCache", isDirectory: true)
    }

    static func clearSync() {
        let fm = FileManager.default
        let rc = baseURL()
        if fm.fileExists(atPath: rc.path) {
            let trash = rc.deletingLastPathComponent().appendingPathComponent("ReconCache_trash_\(UUID().uuidString)")
            _ = try? fm.moveItem(at: rc, to: trash)
            _ = try? fm.createDirectory(at: rc, withIntermediateDirectories: true)
            _ = try? fm.removeItem(at: trash)
        }
    }
}


