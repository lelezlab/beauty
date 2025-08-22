import UIKit
import Foundation

final class CaptureStore {
    static let shared = CaptureStore()
    private init() {}

    var frontImage: UIImage?
    var frontLandmarks: FacialLandmarksResult?
    var selectedProcedure: Procedure?
    var leftImage: UIImage?
    var rightImage: UIImage?
    var leftLandmarks: FacialLandmarksResult?
    var rightLandmarks: FacialLandmarksResult?

    // 本地历史记录
    struct CaptureRecord: Codable, Identifiable {
        let id: String
        let date: Date
        let frontPath: String
        let leftPath: String
        let rightPath: String
    }

    private let fm = FileManager.default
    private lazy var storeDir: URL = {
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Captures", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    private lazy var indexURL: URL = storeDir.appendingPathComponent("captures.json")
    private(set) var records: [CaptureRecord] = []

    func loadRecords() {
        if let data = try? Data(contentsOf: indexURL), let arr = try? JSONDecoder().decode([CaptureRecord].self, from: data) {
            records = arr.sorted { $0.date > $1.date }
        }
    }

    private func persistIndex() {
        _ = try? JSONEncoder().encode(records).write(to: indexURL)
    }

    func saveSession(front: UIImage, left: UIImage, right: UIImage) {
        let id = UUID().uuidString
        let fURL = storeDir.appendingPathComponent("\(id)_front.jpg")
        let lURL = storeDir.appendingPathComponent("\(id)_left.jpg")
        let rURL = storeDir.appendingPathComponent("\(id)_right.jpg")
        _ = try? front.jpegData(compressionQuality: 0.9)?.write(to: fURL)
        _ = try? left.jpegData(compressionQuality: 0.9)?.write(to: lURL)
        _ = try? right.jpegData(compressionQuality: 0.9)?.write(to: rURL)
        let rec = CaptureRecord(id: id, date: Date(), frontPath: fURL.path, leftPath: lURL.path, rightPath: rURL.path)
        records.insert(rec, at: 0)
        persistIndex()
    }
}


