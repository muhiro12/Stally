//
//  StallyAdjustHistoryPreview.swift
//  Stally
//
//  Created by Codex on 2026/07/12.
//

#if DEBUG
import SwiftUI

struct StallyAdjustHistoryPreview: View {
    let items: [Item]
    let itemName: String

    private var selectedItem: Item? {
        items.first { item in
            item.name == itemName
        }
    }

    var body: some View {
        let timeZone = StallyPreviewData.timeZone
        let now = Date()
        let today = LocalDay(containing: now, in: timeZone)
        let todayDate = today?.date(in: timeZone)

        if let selectedItem,
           let today,
           let todayDate {
            AdjustHistoryView(
                item: selectedItem,
                timeZone: timeZone,
                today: today,
                todayDate: todayDate
            )
        } else {
            ContentUnavailableView {
                Label {
                    Text(verbatim: "No Preview Item")
                } icon: {
                    Image(systemName: "tray")
                }
            } description: {
                Text(verbatim: "Preview data did not create an item.")
            }
        }
    }
}
#endif
