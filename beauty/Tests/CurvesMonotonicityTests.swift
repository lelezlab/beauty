import XCTest

final class CurvesMonotonicityTests: XCTestCase {
    func testCurvesFileExists() {
        let path = Bundle.main.path(forResource: "Core/Deform/ParamMappingCurves", ofType: "json")
        XCTAssertNotNil(path)
    }
}


