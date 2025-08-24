import Foundation

enum ProofZipper {
    // Best-effort zip. On iOS, Process is unavailable — return false and let caller share individual files.
    @discardableResult
    static func zip(at directory: URL, to zipURL: URL) -> Bool {
        #if os(macOS)
        let fm = FileManager.default
        let targets = [
            "mockTrueDepth/demo.mp4",
            "mockTrueDepth/diagnostics.png",
            "triView/demo.mp4",
            "triView/diagnostics.png"
        ].map { directory.appendingPathComponent($0).path }
        let existing = targets.filter { fm.fileExists(atPath: $0) }
        guard !existing.isEmpty else { return false }
        let task = Process()
        task.launchPath = "/usr/bin/zip"
        task.arguments = ["-r", zipURL.path] + existing
        do {
            try? fm.removeItem(at: zipURL)
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch { return false }
        #else
        return false
        #endif
    }
}


