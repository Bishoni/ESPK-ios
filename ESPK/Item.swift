//
//  Item.swift
//  ESPK
//
//  Created by mac_mini on 01.10.2025.
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
