import SwiftUI

/// One concise action vocabulary for context menus and ordinary native menus.
struct ItemContextActions: View {
    let snapshot: ItemContextSnapshot
    let editAction: () -> Void
    let mutationAction: (ItemContextMutation) -> Void

    var body: some View {
        if snapshot.capabilities.canChangeHistory {
            if snapshot.isMarkedToday {
                Button {
                    mutationAction(.undoToday)
                } label: {
                    Label("Undo Today's Mark", systemImage: "arrow.uturn.backward")
                }
            } else {
                Button {
                    mutationAction(.markToday)
                } label: {
                    Label("Mark Today", systemImage: "checkmark.circle")
                }
            }
        }
        Button(action: editAction) {
            Label("Edit Item", systemImage: "pencil")
        }
        StallyLinkShareButton(link: .item(snapshot.itemID), title: "Share Item Link")
        if let timeReport = snapshot.timeReport {
            ShareLink(item: timeReport) {
                Label("Share Time Together", systemImage: "clock")
            }
        }
        Divider()
        if snapshot.capabilities.canArchive {
            Button {
                mutationAction(.archive)
            } label: {
                Label("Archive Item", systemImage: "archivebox")
            }
        }
        if snapshot.capabilities.canMoveBackToLibrary {
            Button {
                mutationAction(.moveBackToLibrary)
            } label: {
                Label("Move Back to Library", systemImage: "tray.and.arrow.up")
            }
        }
    }
}
