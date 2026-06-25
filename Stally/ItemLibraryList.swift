//
//  ItemLibraryList.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftUI

struct ItemLibraryList: View {
    let items: [Item]

    var body: some View {
        List(items) { item in
            NavigationLink {
                ItemDetailView(item: item)
            } label: {
                ItemRow(item: item)
            }
        }
    }
}
