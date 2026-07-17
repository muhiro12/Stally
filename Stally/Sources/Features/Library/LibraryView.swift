//
//  LibraryView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.locale)
    private var locale

    @State private var sampleErrorMessage: String?

    let items: [Item]
    let allowsSampleItems: Bool
    let addAction: () -> Void
    let restoreAction: () -> Void

    private var isShowingSampleError: Binding<Bool> {
        .init(
            get: { sampleErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    sampleErrorMessage = nil
                }
            }
        )
    }

    private var sampleAction: (() -> Void)? {
        guard allowsSampleItems else {
            return nil
        }

        return addSampleItems
    }

    var body: some View {
        Group {
            if items.isEmpty {
                EmptyLibraryView(
                    addAction: addAction,
                    sampleAction: sampleAction,
                    restoreAction: restoreAction
                )
            } else {
                ItemLibraryList(items: items, kind: .library)
            }
        }
        .navigationTitle("Library")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                StallyLinkShareButton(
                    link: .destination(.library),
                    title: "Share Library Link"
                )

                Button(action: addAction) {
                    Label("Add Item", systemImage: "plus")
                }
                .stallyToolbarActionStyle()
            }
        }
        .alert("Could Not Add Sample Items", isPresented: isShowingSampleError) {
            Button("OK", role: .cancel) {
                sampleErrorMessage = nil
            }
        } message: {
            if let sampleErrorMessage {
                Text(sampleErrorMessage)
            }
        }
    }

    private func addSampleItems() {
        do {
            let createdItems = try SampleDataOperations.createItemsIfLibraryIsEmpty(
                in: modelContext,
                locale: locale
            )

            if createdItems.isEmpty {
                sampleErrorMessage = String(
                    localized: "Sample items can only be added when the collection is empty."
                )
            }
        } catch {
            sampleErrorMessage = error.localizedDescription
        }
    }
}
