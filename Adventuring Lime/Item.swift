//
//  Item.swift
//  Adventuring Lime
//
//  Created by Christian Jason Sumitro on 17/01/26.
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
