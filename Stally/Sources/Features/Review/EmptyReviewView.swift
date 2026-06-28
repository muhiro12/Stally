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
        ContentUnavailableView {
            Label("Nothing Needs Review", systemImage: "checkmark.circle")
        } description: {
            Text("All review lanes are clear right now.")
        }
        .mhEmptyStateLayout()
    }
}
