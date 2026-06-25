//
//  QuietHistoryDay.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import Foundation

struct QuietHistoryDay: Identifiable {
    let day: Date
    let isMarked: Bool

    var id: Date {
        day
    }
}
