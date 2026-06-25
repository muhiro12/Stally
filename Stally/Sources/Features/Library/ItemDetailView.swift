//
//  ItemDetailView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftData
import SwiftUI

struct ItemDetailView: View {
    @Environment(\.calendar)
    private var calendar

    @Environment(\.modelContext)
    private var modelContext

    let item: Item

    @State private var saveErrorMessage: String?

    private var history: ItemHistorySnapshot {
        ItemOperations.historySnapshot(for: item, calendar: calendar)
    }

    private var isMarkedToday: Bool {
        ItemOperations.isMarked(item, on: .now, calendar: calendar)
    }

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
        List {
            ItemDetailHeaderSection(item: item)

            if !item.isArchived {
                TodayMarkSection(
                    isMarkedToday: isMarkedToday,
                    markAction: markToday,
                    undoAction: undoToday
                )
            }

            ArchiveActionSection(
                isArchived: item.isArchived,
                archiveAction: archiveItem,
                moveBackAction: moveBackToLibrary
            )

            HistoryOverviewSection(history: history)

            QuietHistorySection(history: history)
        }
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
        performSave {
            try ItemOperations.mark(
                item,
                on: .now,
                context: modelContext,
                calendar: calendar
            )
        }
    }

    private func undoToday() {
        performSave {
            try ItemOperations.undoMark(
                item,
                on: .now,
                context: modelContext,
                calendar: calendar
            )
        }
    }

    private func performSave(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func archiveItem() {
        performSave {
            try ItemOperations.archive(
                item,
                on: .now,
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
