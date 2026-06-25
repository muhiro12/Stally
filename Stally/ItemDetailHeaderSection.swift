//
//  ItemDetailHeaderSection.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

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
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(item.category.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.body)
                        .padding(.top, Layout.noteTopPadding)
                }
            }
            .padding(.vertical, Layout.verticalPadding)
        }
    }
}
