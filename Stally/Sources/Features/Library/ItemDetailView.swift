//
//  ItemDetailView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftData
import SwiftUI

struct ItemDetailView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.timeZone)
    private var timeZone

    let item: Item

    @State private var saveErrorMessage: String?

    private var isShowingSaveError: Binding<Bool> {
        Binding {
            saveErrorMessage != nil
        } set: { isPresented in
            if !isPresented {
                saveErrorMessage = nil
            }
        }
    }

    var body: some View {
        let now = Date()
        let today = LocalDay(containing: now, in: timeZone)
        let history = today.map { today in
            ItemOperations.historySnapshot(for: item, today: today)
        }

        List {
            ItemDetailHeaderSection(item: item)

            if !item.isArchived, let today {
                TodayMarkSection(
                    isMarkedToday: ItemOperations.isMarked(item, on: today),
                    markAction: markToday,
                    undoAction: undoToday
                )
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
        }
        .stallyListChrome()
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StallyLinkShareButton(
                    link: .item(item.uuid),
                    title: "Share Item Link"
                )
            }
        }
        .alert("Could Not Save", isPresented: isShowingSaveError) {
            Button("OK", role: .cancel, action: clearSaveError)
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private func markToday() {
        guard let today = currentDay() else {
            saveErrorMessage = String(localized: "Could Not Save")
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
            saveErrorMessage = String(localized: "Could Not Save")
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
            saveErrorMessage = error.localizedDescription
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

    private func clearSaveError() {
        saveErrorMessage = nil
    }
}
