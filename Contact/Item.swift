//
//  Item.swift
//  Contact
//
//  Created by Thomas Patrick on 5/20/24.
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
