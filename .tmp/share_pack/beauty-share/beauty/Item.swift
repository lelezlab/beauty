//
//  Item.swift
//  beauty
//
//  Created by 张丽媛 on 8/18/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

// MARK: - Before/After slider preview component
struct BeforeAfterSlider: View {
    let before: UIImage
    let after: UIImage
    @State private var ratio: CGFloat = 0.5
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack(alignment: .leading) {
                Image(uiImage: before).resizable().scaledToFill().frame(width: size.width, height: size.height).clipped()
                Image(uiImage: after).resizable().scaledToFill().frame(width: size.width * ratio, height: size.height, alignment: .leading).clipped()
                Rectangle().fill(Color.white).frame(width: 2, height: size.height).position(x: size.width * ratio, y: size.height/2)
                Circle().fill(.ultraThinMaterial).frame(width: 28, height: 28).overlay(Image(systemName: "arrow.left.and.right")).position(x: size.width * ratio, y: size.height/2)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                let x = max(0, min(size.width, v.location.x))
                ratio = x / size.width
            })
        }
    }
}
