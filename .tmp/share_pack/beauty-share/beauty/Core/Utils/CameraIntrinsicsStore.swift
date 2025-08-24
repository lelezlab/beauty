import Foundation
import simd

enum CameraIntrinsicsStore {
    static func save(_ K: simd_float3x3) {
        let arr = [K[0,0],K[0,1],K[0,2],K[1,0],K[1,1],K[1,2],K[2,0],K[2,1],K[2,2]]
        UserDefaults.standard.set(arr, forKey: "camera_intrinsics_v1")
    }
    static func load() -> simd_float3x3? {
        guard let arr = UserDefaults.standard.array(forKey: "camera_intrinsics_v1") as? [Float], arr.count == 9 else { return nil }
        return simd_float3x3(rows: [SIMD3(arr[0],arr[1],arr[2]), SIMD3(arr[3],arr[4],arr[5]), SIMD3(arr[6],arr[7],arr[8])])
    }
}


