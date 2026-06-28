//
//  ItemDetailHeaderSection.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHUI
import SwiftUI

struct ItemDetailHeaderSection: View {
    private enum Layout {
        static let verticalSpacing: CGFloat = 8
        static let noteTopPadding: CGFloat = 4
        static let verticalPadding: CGFloat = 4
    }

    let item: Item

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                Text(item.name)
                    .mhTextStyle(.screenTitle)

                Text(item.category.title)
                    .mhBadge(style: .neutral)

                if !item.note.isEmpty {
                    Text(item.note)
                        .mhTextStyle(.body, colorRole: .secondaryText)
                        .padding(.top, Layout.noteTopPadding)
                }
            }
            .padding(.vertical, Layout.verticalPadding)
        }
    }
}
