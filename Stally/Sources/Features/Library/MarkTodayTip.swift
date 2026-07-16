//
//  MarkTodayTip.swift
//  Stally
//
//  Created by Codex on 2026/07/16.
//

import SwiftUI
import TipKit

struct MarkTodayTip: Tip {
    var title: Text {
        Text("One mark is enough for today.")
    }

    var options: [Option] {
        MaxDisplayCount(1)
    }
}
