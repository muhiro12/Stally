//
//  EmptyArchiveView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct EmptyArchiveView: View {
    var body: some View {
        List {
            // Preserve the native list canvas behind the empty state.
        }
        .stallyListChrome()
        .overlay {
            ContentUnavailableView {
                Label("No Archived Items", systemImage: "archivebox")
            } description: {
                Text("Past favorites can stay nearby without crowding the main list.")
            }
            .mhEmptyStateLayout()
        }
    }
}
