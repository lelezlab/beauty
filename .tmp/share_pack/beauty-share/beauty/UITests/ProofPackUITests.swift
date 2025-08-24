#if canImport(XCTest)
import XCTest

final class ProofPackUITests: XCTestCase {
    func testProofPackGeneration() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-DebugMenu", "1"]
        app.launch()

        // Open Settings/Developer/Proof Pack regardless of current tab
        if app.tabBars.buttons["设置"].exists { app.tabBars.buttons["设置"].tap() }
        if app.staticTexts["Proof Pack"].exists { app.staticTexts["Proof Pack"].tap() }
        if app.buttons["Run BOTH"].exists == false {
            // Fallback: try Developer first
            if app.staticTexts["Developer"].exists { app.staticTexts["Developer"].tap() }
            if app.staticTexts["Proof Pack"].exists { app.staticTexts["Proof Pack"].tap() }
        }

        // Run BOTH (with fallback toast if tri-view samples are missing)
        if app.buttons["Run BOTH"].exists { app.buttons["Run BOTH"].tap() }

        // Wait for completion marker
        let done = app.staticTexts["ProofDone"]
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: done)
        waitForExpectations(timeout: 120)

        // Verify files (allow presence-only; missing triView pair acceptable on fallback)
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let expected = [
            "proof/mockTrueDepth/demo.mp4",
            "proof/mockTrueDepth/diagnostics.png",
            "proof/triView/demo.mp4",
            "proof/triView/diagnostics.png"
        ]
        var present = 0
        for f in expected {
            if FileManager.default.fileExists(atPath: docs.appendingPathComponent(f).path) { present += 1 }
        }
        XCTAssertTrue(present >= 2, "At least the Mock pair should exist; found \(present)")
    }
}
#endif


