//
//  ItemPhotoFeedback.swift
//  Stally
//
//  Created by Codex on 2026/07/17.
//

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
                    .foregroundStyle(.red)

                Text(errorMessage)
                    .foregroundStyle(.secondary)

                Text("Choose another photo and try again.")
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
