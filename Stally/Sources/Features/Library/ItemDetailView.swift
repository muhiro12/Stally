//
//  ItemDetailView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHUI
import SwiftData
import SwiftUI
import UIKit

struct ItemDetailView: View {
    private struct HistoryAdjustmentContext {
        let timeZone: TimeZone
        let today: LocalDay
        let todayDate: Date
    }

    private enum PresentedSheet: Identifiable {
        case adjustHistory(HistoryAdjustmentContext)
        case editItem

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
    @Environment(\.mhTheme)
    private var theme
    @Environment(\.locale)
    private var locale
    @Environment(\.scenePhase)
    private var scenePhase

    @Environment(Item.self)
    private var item

    @State private var presentedSheet: PresentedSheet?
    @State private var isConfirmingDeleteItem = false
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var isPresentingError = false
    @State private var readingDate = Date()

    var body: some View {
        let now = readingDate
        let today = LocalDay(containing: now, in: timeZone)
        let history = today.map { today in
            ItemOperations.historySnapshot(for: item, today: today)
        }
        let isMarkedToday = today.map { today in
            ItemOperations.isMarked(item, on: today)
        } ?? false
        let canChangeHistory = ItemOperations.historyChangeError(for: item) == nil

        List {
            Section {
                ItemDetailSummary(
                    isMarkedToday: isMarkedToday
                )
            }

            if let photoData = item.photoData {
                ItemDetailPhotoSection(photoData: photoData)
            }

            if let today {
                timeSection(today: today)
            }

            if ItemOperations.hasNonMarkHistoryConflict(item) {
                Section {
                    Text("Keep Marks enabled to preserve this item's existing history.")
                }
            }

            if let history, item.recordsMarks || ItemOperations.hasNonMarkHistoryConflict(item) {
                historySections(
                    history: history,
                    canChangeHistory: canChangeHistory
                )
            }

            ArchiveActionSection(
                isArchived: item.isArchived,
                archiveAction: archiveItem,
                moveBackAction: moveBackToLibrary
            )

            ItemDeletionSection(deleteAction: confirmDeleteItem)
        }
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .safeAreaBar(edge: .bottom) {
            if canChangeHistory {
                TodayMarkSection(
                    isMarkedToday: isMarkedToday,
                    markAction: markToday,
                    undoAction: undoToday
                )
                .frame(maxWidth: theme.layout.readableContentWidth)
                .padding(.horizontal, theme.spacing.content)
                .padding(.vertical, theme.spacing.inline)
            }
        }
        .mhListChrome(.native)
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            readingDate = .now
        }
        .onChange(of: timeZone) {
            readingDate = .now
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                readingDate = .now
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: presentEditItem) {
                    Label("Edit Item", systemImage: "pencil")
                }
                .stallyToolbarActionStyle()

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
                    timeZone: context.timeZone,
                    today: context.today,
                    todayDate: context.todayDate
                )
                .environment(item)
            case .editItem:
                EditItemView()
                    .environment(item)
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
}

private extension ItemDetailView {
    @ViewBuilder
    private func historySections(
        history: ItemHistorySnapshot,
        canChangeHistory: Bool
    ) -> some View {
        HistoryOverviewSection(history: history)

        QuietHistorySection(
            history: history,
            canChangeHistory: canChangeHistory,
            adjustAction: presentHistoryAdjustment
        )
    }

    private func timeSection(today: LocalDay) -> some View {
        ItemTimeSection(
            snapshot: ItemTimeOperations.snapshot(for: item, today: today),
            milestone: ItemTimeOperations.milestone(for: item, today: today),
            report: ItemTimeOperations.report(for: item, today: today, locale: locale)
        )
    }

    func markToday() {
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
        presentedSheet = .editItem
    }

    private func presentHistoryAdjustment() {
        if let error = ItemOperations.historyChangeError(for: item) {
            presentError(title: String(localized: "Could Not Update History"), message: error.localizedDescription)
            return
        }
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
