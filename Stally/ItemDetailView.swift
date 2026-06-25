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
        item.historySnapshot(calendar: calendar)
    }

    private var isMarkedToday: Bool {
        item.isMarked(on: .now, calendar: calendar)
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

            TodayMarkSection(
                isMarkedToday: isMarkedToday,
                markAction: markToday,
                undoAction: undoToday
            )

            HistoryOverviewSection(history: history)

            QuietHistorySection(history: history)
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Could Not Save", isPresented: isShowingSaveError) {
            Button("OK", role: .cancel, action: clearSaveError)
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private func markToday() {
        guard let mark = item.addMark(on: .now, calendar: calendar) else {
            return
        }

        modelContext.insert(mark)
        saveChanges()
    }

    private func undoToday() {
        guard let mark = item.removeMark(on: .now, calendar: calendar) else {
            return
        }

        modelContext.delete(mark)
        saveChanges()
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func clearSaveError() {
        saveErrorMessage = nil
    }
}
