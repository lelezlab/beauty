import Foundation

protocol TelemetryUploader {
    func enqueue(_ batch: [BTEvent]) throws
    func flush() async
}

final class FileTelemetryQueue {
    private let fm = FileManager.default
    private let queueURL: URL
    private let lock = NSLock()
    init(filename: String = "telemetry.queue.json") {
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("BTQueue", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        queueURL = dir.appendingPathComponent(filename)
    }
    func readAll() -> [BTEvent] {
        lock.lock(); defer { lock.unlock() }
        guard let data = try? Data(contentsOf: queueURL) else { return [] }
        return (try? JSONDecoder().decode([BTEvent].self, from: data)) ?? []
    }
    func writeAll(_ events: [BTEvent]) {
        lock.lock(); defer { lock.unlock() }
        if let data = try? JSONEncoder().encode(events) { try? data.write(to: queueURL) }
    }
    func append(_ events: [BTEvent]) {
        var all = readAll()
        all.append(contentsOf: events)
        writeAll(all)
    }
}


