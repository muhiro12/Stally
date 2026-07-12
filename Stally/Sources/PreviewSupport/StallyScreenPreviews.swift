//
//  StallyScreenPreviews.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

#if DEBUG
import SwiftUI

#Preview("Library - Empty") {
    StallyPreviewContainer(.empty) { items in
        LibraryView(
            items: ItemOperations.activeItems(from: items),
            addAction: { /* Preview action intentionally left empty. */ },
            settingsAction: { /* Preview action intentionally left empty. */ }
        )
    }
}

#Preview("Library - Typical") {
    StallyPreviewContainer(.typical) { items in
        LibraryView(
            items: ItemOperations.activeItems(from: items),
            addAction: { /* Preview action intentionally left empty. */ },
            settingsAction: { /* Preview action intentionally left empty. */ }
        )
    }
}

#Preview("Library - Dense Dark") {
    StallyPreviewContainer(.dense) { items in
        LibraryView(
            items: ItemOperations.activeItems(from: items),
            addAction: { /* Preview action intentionally left empty. */ },
            settingsAction: { /* Preview action intentionally left empty. */ }
        )
        .preferredColorScheme(.dark)
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

#Preview("Archive - Preserved Items") {
    StallyPreviewContainer(.dense) { items in
        ArchiveView(items: ItemOperations.archivedItems(from: items))
    }
}

#Preview("Archive - Empty") {
    StallyPreviewContainer(.empty) { _ in
        ArchiveView(items: [])
    }
}

#Preview("Review - Attention Lanes") {
    StallyPreviewContainer(.dense) { items in
        let now = Date()

        ReviewView(
            snapshot: ReviewOperations.snapshot(
                for: items,
                timeZone: StallyPreviewData.timeZone,
                now: now
            )
        )
    }
}

#Preview("Review - Empty") {
    StallyPreviewContainer(.empty) { items in
        let now = Date()

        ReviewView(
            snapshot: ReviewOperations.snapshot(
                for: items,
                timeZone: StallyPreviewData.timeZone,
                now: now
            )
        )
    }
}

#Preview("Insights - Typical") {
    StallyPreviewContainer(.dense) { items in
        InsightsView(items: items)
    }
}

#Preview("Backup Center - Snapshot") {
    StallyPreviewContainer(.dense) { items in
        BackupCenterView(items: items)
    }
}

#Preview("Backup Center - Import Preview") {
    StallyPreviewContainer(.dense) { items in
        NavigationStack {
            BackupList(
                summary: .init(items: items),
                preview: StallyPreviewData.backupValidationPreview,
                statusMessage: "Backup saved.",
                exportAction: { /* Preview action intentionally left empty. */ },
                chooseBackupAction: { /* Preview action intentionally left empty. */ },
                mergeAction: { /* Preview action intentionally left empty. */ },
                replaceAction: { /* Preview action intentionally left empty. */ },
                deleteEverythingAction: { /* Preview action intentionally left empty. */ }
            )
            .navigationTitle("Backup Center")
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
                ItemDetailView(item: selectedItem)
            } else {
                ContentUnavailableView {
                    Label("No Preview Item", systemImage: "tray")
                } description: {
                    Text("Preview data did not create an item.")
                }
            }
        }
    }
}

#endif
