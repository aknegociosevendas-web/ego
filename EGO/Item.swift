//
//  Item.swift
//  EGO
//
//  Created by Vitor Froes souto on 09/07/26.
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
