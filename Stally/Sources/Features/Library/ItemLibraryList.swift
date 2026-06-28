//
//  ItemLibraryList.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHPlatform
import SwiftUI

struct ItemLibraryList: View {
    @AppStorage(\.isSubscribeOn)
    private var isSubscribeOn

    let items: [Item]

    var body: some View {
        List {
            ForEach(items) { item in
                NavigationLink {
                    ItemDetailView(item: item)
                } label: {
                    ItemRow(item: item)
                }
            }

            if !isSubscribeOn {
                StallyAdvertisementSection(size: .small)
            }
        }
        .stallyListChrome()
    }
}
