//
//  Item.swift
//  beauty
//
//  Created by 张丽媛 on 8/18/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
