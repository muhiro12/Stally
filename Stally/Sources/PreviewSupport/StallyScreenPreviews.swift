//
//  StallyScreenPreviews.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

#if DEBUG
import SwiftUI

#Preview("Library - Empty") {
    StallyPreviewContainer(.empty) { _ in
        NavigationStack {
            LibraryView(
                addAction: { /* Preview action intentionally left empty. */ },
                restoreAction: { /* Preview action intentionally left empty. */ }
            )
        }
    }
}

#Preview("Library - Typical") {
    StallyPreviewContainer(.typical) { _ in
        NavigationStack {
            LibraryView(
                addAction: { /* Preview action intentionally left empty. */ },
                restoreAction: { /* Preview action intentionally left empty. */ }
            )
        }
    }
}

#Preview("Library - Dense Dark") {
    StallyPreviewContainer(.dense) { _ in
        NavigationStack {
            LibraryView(
                addAction: { /* Preview action intentionally left empty. */ },
                restoreAction: { /* Preview action intentionally left empty. */ }
            )
            .preferredColorScheme(.dark)
        }
    }
}

#Preview("Item Detail - Long Text Large Type") {
    StallyPreviewContainer(.dense) { items in
        StallyScreenPreviews(items: items)
            .environment(\.dynamicTypeSize, .accessibility2)
    }
}

#Preview("Add Item - Empty Form") {
    StallyPreviewContainer(.empty) { _ in
        AddItemView()
    }
}

#Preview("Edit Item - Existing Values") {
    StallyPreviewContainer(.typical) { items in
        StallyEditItemPreview(items: items)
    }
}

#Preview("Adjust History - Marked Day") {
    StallyPreviewContainer(.typical) { items in
        StallyAdjustHistoryPreview(
            items: items,
            itemName: "Black Wool Coat"
        )
    }
}

#Preview("Adjust History - Unmarked Day") {
    StallyPreviewContainer(.typical) { items in
        StallyAdjustHistoryPreview(
            items: items,
            itemName: "Daily Field Notes"
        )
    }
}

#Preview("Archive - Preserved Items") {
    StallyPreviewContainer(.dense) { _ in
        NavigationStack {
            ArchiveView()
        }
    }
}

#Preview("Archive - Empty") {
    StallyPreviewContainer(.empty) { _ in
        NavigationStack {
            ArchiveView()
        }
    }
}

#Preview("Review - Attention Lanes") {
    StallyPreviewContainer(.dense) { _ in
        NavigationStack {
            ReviewView()
        }
    }
}

#Preview("Review - Empty") {
    StallyPreviewContainer(.empty) { _ in
        NavigationStack {
            ReviewView()
        }
    }
}

#Preview("Insights - Typical") {
    StallyPreviewContainer(.dense) { _ in
        NavigationStack {
            InsightsView()
        }
    }
}

#Preview("Import & Export - Snapshot") {
    StallyPreviewContainer(.dense) { _ in
        NavigationStack {
            BackupCenterView()
        }
    }
}

#Preview("Import & Export - Import Preview") {
    StallyPreviewContainer(.dense) { items in
        NavigationStack {
            BackupList(
                summary: .init(items: items),
                preview: StallyPreviewData.backupValidationPreview,
                isReplacingExistingItems: .constant(false),
                statusMessage: "Data saved.",
                exportAction: { /* Preview action intentionally left empty. */ },
                chooseBackupAction: { /* Preview action intentionally left empty. */ },
                mergeAction: { /* Preview action intentionally left empty. */ },
                replaceAction: { /* Preview action intentionally left empty. */ },
                deleteEverythingAction: { /* Preview action intentionally left empty. */ }
            )
            .navigationTitle("Import & Export")
        }
    }
}

#Preview("Settings - Shareable Links") {
    StallyPreviewContainer(.typical) { _ in
        SettingsView()
    }
}

private struct StallyScreenPreviews: View {
    let items: [Item]

    private var selectedItem: Item? {
        items.first { item in
            item.name == "Soft Navy Sweater With A Long Familiar Name"
        } ?? ItemOperations.activeItems(from: items).first
    }

    var body: some View {
        NavigationStack {
            if let selectedItem {
                ItemDetailView()
                    .environment(selectedItem)
            } else {
                ContentUnavailableView {
                    Label {
                        Text(verbatim: "No Preview Item")
                    } icon: {
                        Image(systemName: "tray")
                    }
                } description: {
                    Text(verbatim: "Preview data did not create an item.")
                }
            }
        }
    }
}

#endif
