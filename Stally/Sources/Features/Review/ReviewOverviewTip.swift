//
//  ReviewOverviewTip.swift
//  Stally
//
//  Created by Codex on 2026/07/16.
//

import SwiftUI
import TipKit

struct ReviewOverviewTip: Tip {
    var title: Text {
        Text("Notice what has gone quiet")
    }

    var message: Text? {
        Text(
            "Review brings together items waiting for a first mark, dormant items, and past favorites that may return."
        )
    }

    var image: Image? {
        Image(systemName: "text.badge.checkmark")
    }

    var options: [Option] {
        MaxDisplayCount(1)
    }
}
