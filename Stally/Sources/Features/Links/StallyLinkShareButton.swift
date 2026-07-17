//
//  StallyLinkShareButton.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct StallyLinkShareButton: View {
    let link: StallyLink
    let title: LocalizedStringResource

    private var url: URL {
        StallyLinkOperations.url(for: link)
    }

    var body: some View {
        ShareLink(item: url) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .stallyToolbarActionStyle()
    }
}
