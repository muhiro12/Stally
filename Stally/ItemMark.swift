//
//  ItemMark.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import Foundation
import SwiftData

@Model
final class ItemMark {
    var day: Date
    var createdAt: Date
    var item: Item?

    init(day: Date, createdAt: Date = .now, item: Item? = nil) {
        self.day = day
        self.createdAt = createdAt
        self.item = item
    }
}
