//
//  ItemPhotoFeedback.swift
//  Stally
//
//  Created by Codex on 2026/07/17.
//

import MHUI
import SwiftUI

struct ItemPhotoFeedback: View {
    let isLoading: Bool
    let errorMessage: String?

    var body: some View {
        VStack(alignment: .leading) {
            if isLoading {
                ProgressView("Preparing Photo")
            }

            if let errorMessage {
                Label("Could Not Use Photo", systemImage: "exclamationmark.triangle")
                    .mhForegroundStyle(.destructive)

                Text(errorMessage)
                    .mhForegroundStyle(.secondaryText)

                Text("Choose another photo and try again.")
                    .mhForegroundStyle(.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
