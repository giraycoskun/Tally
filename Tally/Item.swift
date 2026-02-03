//
//  Item.swift
//  Tally
//
//  Created by Giray Coskun on 3.02.2026.
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
