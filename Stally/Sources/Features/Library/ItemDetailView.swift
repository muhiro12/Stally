//
//  ItemDetailView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftData
import SwiftUI

struct ItemDetailView: View {
    private struct HistoryAdjustmentContext: Identifiable {
        let item: Item
        let timeZone: TimeZone
        let today: LocalDay
        let todayDate: Date

        var id: UUID {
            item.uuid
        }
    }

    private enum PresentedSheet: Identifiable {
        case adjustHistory(HistoryAdjustmentContext)
        case editItem(Item)

        var id: String {
            switch self {
            case .adjustHistory:
                "adjust-history"
            case .editItem:
                "edit-item"
            }
        }
    }

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.timeZone)
    private var timeZone

    let item: Item

    @State private var presentedSheet: PresentedSheet?
    @State private var isConfirmingDeleteItem = false
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var isPresentingError = false

    var body: some View {
        let now = Date()
        let today = LocalDay(containing: now, in: timeZone)
        let history = today.map { today in
            ItemOperations.historySnapshot(for: item, today: today)
        }

        List {
            ItemDetailSummary(item: item)

            if let photoData = item.photoData {
                ItemDetailPhotoSection(photoData: photoData)
            }

            if !item.isArchived, let today {
                TodayMarkSection(
                    isMarkedToday: ItemOperations.isMarked(item, on: today),
                    markAction: markToday,
                    undoAction: undoToday
                )

                HistoryAdjustmentEntrySection(adjustAction: presentHistoryAdjustment)
            }

            ArchiveActionSection(
                isArchived: item.isArchived,
                archiveAction: archiveItem,
                moveBackAction: moveBackToLibrary
            )

            if let history {
                HistoryOverviewSection(history: history)

                QuietHistorySection(history: history)
            }

            ItemDeletionSection(deleteAction: confirmDeleteItem)
        }
        .stallyListChrome()
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: presentEditItem) {
                    Label("Edit Item", systemImage: "pencil")
                }

                StallyLinkShareButton(
                    link: .item(item.uuid),
                    title: "Share Item Link"
                )
            }
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .adjustHistory(let context):
                AdjustHistoryView(
                    item: context.item,
                    timeZone: context.timeZone,
                    today: context.today,
                    todayDate: context.todayDate
                )
            case .editItem(let item):
                EditItemView(item: item)
            }
        }
        .alert("Delete Item?", isPresented: $isConfirmingDeleteItem) {
            Button("Delete Item", role: .destructive, action: deleteItem)
            Button("Cancel", role: .cancel, action: cancelDeleteItem)
        } message: {
            Text("This item and all of its marks will be permanently deleted. This cannot be undone.")
        }
        .alert(errorTitle, isPresented: $isPresentingError) {
            Button("OK", role: .cancel, action: clearError)
        } message: {
            Text(errorMessage)
        }
    }

    private func markToday() {
        guard let today = currentDay() else {
            presentError(
                title: String(localized: "Could Not Save"),
                message: String(localized: "Could Not Save")
            )
            return
        }

        performSave {
            try ItemOperations.mark(
                item,
                on: today,
                today: today,
                context: modelContext
            )
        }
    }

    private func undoToday() {
        guard let today = currentDay() else {
            presentError(
                title: String(localized: "Could Not Save"),
                message: String(localized: "Could Not Save")
            )
            return
        }

        performSave {
            try ItemOperations.undoMark(
                item,
                on: today,
                context: modelContext
            )
        }
    }

    private func currentDay() -> LocalDay? {
        let now = Date()
        return .init(containing: now, in: timeZone)
    }

    private func performSave(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            presentError(
                title: String(localized: "Could Not Save"),
                message: error.localizedDescription
            )
        }
    }

    private func archiveItem() {
        let now = Date()

        performSave {
            try ItemOperations.archive(
                item,
                on: now,
                context: modelContext
            )
        }
    }

    private func moveBackToLibrary() {
        performSave {
            try ItemOperations.moveBackToLibrary(
                item,
                context: modelContext
            )
        }
    }

    private func presentEditItem() {
        presentedSheet = .editItem(item)
    }

    private func presentHistoryAdjustment() {
        let capturedTimeZone = timeZone
        let now = Date()

        guard let today = LocalDay(containing: now, in: capturedTimeZone),
              let todayDate = today.date(in: capturedTimeZone) else {
            presentError(
                title: String(localized: "Could Not Update History"),
                message: String(localized: "Choose a valid day no later than today.")
            )
            return
        }

        presentedSheet = .adjustHistory(
            .init(
                item: item,
                timeZone: capturedTimeZone,
                today: today,
                todayDate: todayDate
            )
        )
    }

    private func confirmDeleteItem() {
        isConfirmingDeleteItem = true
    }

    private func cancelDeleteItem() {
        isConfirmingDeleteItem = false
    }

    private func deleteItem() {
        do {
            try ItemOperations.delete(item, context: modelContext)
            dismiss()
        } catch {
            presentError(
                title: String(localized: "Could Not Delete"),
                message: error.localizedDescription
            )
        }
    }

    private func presentError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        isPresentingError = true
    }

    private func clearError() {
        errorTitle = ""
        errorMessage = ""
        isPresentingError = false
    }
}
