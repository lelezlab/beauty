import SwiftUI

struct FaceLineOverlay: View {
    let size: CGSize
    var body: some View {
        DoctorOverlayView(size: size, landmarks: [:])
    }
}


