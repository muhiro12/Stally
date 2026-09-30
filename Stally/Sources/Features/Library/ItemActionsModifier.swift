import SwiftData
import SwiftUI

struct ItemActionsModifier: ViewModifier {
    enum Presentation {
        case contextMenu
        case toolbarMenu
    }

    private struct Editor: Identifiable {
        let id: UUID
    }

    @Environment(Item.self)
    private var item
    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.stallyReadingDate)
    private var readingDate
    @Environment(\.timeZone)
    private var timeZone
    @Environment(\.locale)
    private var locale

    let presentation: Presentation
    @State private var editor: Editor?
    @State private var errorMessage: String?

    private var isShowingError: Binding<Bool> {
        .init {
            errorMessage != nil
        } set: { presented in
            if !presented {
                errorMessage = nil
            }
        }
    }

    func body(content: Content) -> some View {
        let snapshot = LocalDay(containing: readingDate, in: timeZone).map { today in
            ItemOperations.contextSnapshot(for: item, today: today, locale: locale)
        }
        menuContent(content, snapshot: snapshot)
            .sheet(item: $editor) { destination in
                StallyItemDestinationView(editingItemID: destination.id)
            }
            .alert("Could Not Save", isPresented: isShowingError) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
    }

    @ViewBuilder
    private func menuContent(_ content: Content, snapshot: ItemContextSnapshot?) -> some View {
        switch presentation {
        case .contextMenu:
            content.contextMenu {
                actions(for: snapshot)
            }
        case .toolbarMenu:
            content.toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        actions(for: snapshot)
                    } label: {
                        Label("Item Actions", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func actions(for snapshot: ItemContextSnapshot?) -> some View {
        if let snapshot {
            ItemContextActions(
                snapshot: snapshot,
                editAction: { editor = .init(id: snapshot.itemID) },
                mutationAction: { mutation in
                    perform(mutation, itemID: snapshot.itemID)
                }
            )
        }
    }

    private func perform(_ mutation: ItemContextMutation, itemID: UUID) {
        do {
            guard let currentItem = try ItemOperations.item(context: modelContext, uuid: itemID) else {
                throw StallyIntentError.itemNotFound
            }
            guard let today = LocalDay(containing: StallyActionDate.current, in: timeZone) else {
                throw StallyIntentError.currentDayUnavailable
            }
            switch mutation {
            case .markToday:
                try ItemOperations.mark(currentItem, on: today, today: today, context: modelContext)
            case .undoToday:
                try ItemOperations.undoMark(currentItem, on: today, context: modelContext)
            case .archive:
                try ItemOperations.archive(currentItem, on: StallyActionDate.current, context: modelContext)
            case .moveBackToLibrary:
                try ItemOperations.moveBackToLibrary(currentItem, context: modelContext)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
