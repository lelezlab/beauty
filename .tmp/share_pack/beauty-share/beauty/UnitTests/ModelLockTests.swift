#if canImport(XCTest)
import XCTest
@testable import beauty

final class ModelLockTests: XCTestCase {
    func testModelsReady() throws {
        let ids = ["facemesh_mediapipe_task", "arcface_ir50", "face_parsing_bisenet", "midas_s"]
        for id in ids {
            let path = try ModelRegistry.path(for: id)
            XCTAssertFalse(path.isEmpty)
            XCTAssertTrue((try? Hasher.verifySHA256(filePath: path, hex: (try loadLock()[id] ?? ""))) ?? true)
        }
    }

    private func loadLock() throws -> [String:String] {
        let url = Bundle.main.url(forResource: "models.lock", withExtension: "json", subdirectory: "Resources/Models") ??
                  Bundle.main.url(forResource: "models.lock", withExtension: "json", subdirectory: "Models") ??
                  Bundle.main.url(forResource: "models.lock.seed", withExtension: "json", subdirectory: "Resources/Models")!
        let d = try Data(contentsOf: url)
        let obj = try JSONSerialization.jsonObject(with: d) as! [String:Any]
        let ms = (obj["models"] as? [[String:Any]]) ?? []
        var map: [String:String] = [:]
        for m in ms { if let id = m["id"] as? String, let h = m["sha256"] as? String { map[id] = h } }
        return map
    }
}
#endif



