#if canImport(XCTest)
import XCTest

final class ProofPackUITests: XCTestCase {
    func testProofPackGeneration() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-DebugMenu", "1"]
        app.launch()
        // 尝试找到入口并运行 BOTH
        let appQuery = app
        // 以下步骤视 UI 架构可能需要调整；若菜单不可直接访问，依然检查 proof 目录
        if appQuery.buttons["Developer"].exists { appQuery.buttons["Developer"].tap() }
        if appQuery.buttons["Generate Proof Pack"].exists { appQuery.buttons["Generate Proof Pack"].tap() }
        if appQuery.buttons["Run BOTH"].exists { appQuery.buttons["Run BOTH"].tap() }
        let done = appQuery.staticTexts["ProofDone"]
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: done)
        waitForExpectations(timeout: 90)
        // 校验 4 个文件是否存在
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let files = [
            "proof/mockTrueDepth/demo.mp4",
            "proof/mockTrueDepth/diagnostics.png",
            "proof/triView/demo.mp4",
            "proof/triView/diagnostics.png"
        ]
        for f in files {
            XCTAssertTrue(FileManager.default.fileExists(atPath: docs.appendingPathComponent(f).path), f)
        }
    }
}
#endif


