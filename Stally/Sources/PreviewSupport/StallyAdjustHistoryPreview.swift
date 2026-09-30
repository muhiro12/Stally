//
//  StallyAdjustHistoryPreview.swift
//  Stally
//
//  Created by Codex on 2026/07/12.
//

#if DEBUG
import Foundation
import SwiftUI

struct StallyAdjustHistoryPreview: View {
    let items: [Item]
    let itemID: UUID

    private var selectedItem: Item? {
        items.first { item in
            item.uuid == itemID
        }
    }

    var body: some View {
        let timeZone = StallyPreviewData.timeZone
        let now = StallyPreviewData.referenceDate
        let today = LocalDay(containing: now, in: timeZone)
        let todayDate = today?.date(in: timeZone)

        if let selectedItem,
           let today,
           let todayDate {
            AdjustHistoryView(
                timeZone: timeZone,
                today: today,
                todayDate: todayDate
            )
            .environment(selectedItem)
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
