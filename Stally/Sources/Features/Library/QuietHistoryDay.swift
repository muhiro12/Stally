//
//  QuietHistoryDay.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import Foundation

struct QuietHistoryDay: Identifiable {
    let day: LocalDay
    let isMarked: Bool

    var id: LocalDay {
        day
    }
}
