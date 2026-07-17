//
//  EmptyReviewView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftUI

struct EmptyReviewView: View {
    var body: some View {
        List {
            // Preserve the native list canvas behind the empty state.
        }
        .stallyListChrome()
        .overlay {
            ContentUnavailableView {
                Label("Nothing Needs Review", systemImage: "checkmark.circle")
            } description: {
                Text("All review lanes are clear right now.")
            }
            .mhEmptyStateLayout()
        }
    }
}
