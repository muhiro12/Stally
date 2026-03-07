//
//  CountEntry.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/07.
//

import Foundation
import SwiftData

@Model
final class CountEntry {
    var countedAt: Date
    var item: TrackedItem?

    init(countedAt: Date = .now, item: TrackedItem? = nil) {
        self.countedAt = countedAt
        self.item = item
    }
}
