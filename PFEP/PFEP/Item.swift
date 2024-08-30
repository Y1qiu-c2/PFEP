//
//  Item.swift
//  PFEP
//
//  Created by 邱艺鹏 on 2024/8/28.
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
