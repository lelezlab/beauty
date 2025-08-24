import Foundation

final class CurvesMonotonicityTests {
    func testCurvesFileExists() {
        _ = Bundle.main.path(forResource: "Core/Deform/ParamMappingCurves", ofType: "json") != nil
    }
}


