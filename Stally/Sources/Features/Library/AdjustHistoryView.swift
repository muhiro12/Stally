//
//  AdjustHistoryView.swift
//  Stally
//
//  Created by Codex on 2026/07/12.
//

import SwiftData
import SwiftUI

struct AdjustHistoryView: View {
    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    let item: Item
    let timeZone: TimeZone
    let today: LocalDay
    let todayDate: Date

    @State private var selectedDate: Date
    @State private var errorMessage = ""
    @State private var isPresentingError = false

    private var selectedDay: LocalDay? {
        guard let day = LocalDay(containing: selectedDate, in: timeZone),
              day <= today else {
            return nil
        }

        return day
    }

    private var isSelectedDayMarked: Bool {
        guard let selectedDay else {
            return false
        }

        return ItemOperations.isMarked(item, on: selectedDay)
    }

    var body: some View {
        NavigationStack {
            Form {
                HistoryAdjustmentDateSection(
                    selectedDate: $selectedDate,
                    latestDate: todayDate
                )

                HistoryAdjustmentActionSection(
                    isMarked: isSelectedDayMarked,
                    isSelectionValid: selectedDay != nil,
                    addAction: addMark,
                    removeAction: removeMark
                )
            }
            .stallyFormChrome()
            .navigationTitle("Adjust History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismissSheet)
                        .stallyToolbarActionStyle()
                }
            }
            .alert("Could Not Update History", isPresented: $isPresentingError) {
                Button("OK", role: .cancel, action: clearError)
            } message: {
                Text(errorMessage)
            }
        }
        .environment(\.timeZone, timeZone)
    }

    init(
        item: Item,
        timeZone: TimeZone,
        today: LocalDay,
        todayDate: Date
    ) {
        self.item = item
        self.timeZone = timeZone
        self.today = today
        self.todayDate = todayDate
        _selectedDate = .init(initialValue: todayDate)
    }

    private func addMark() {
        performHistoryUpdate { selectedDay in
            try ItemOperations.mark(
                item,
                on: selectedDay,
                today: today,
                context: modelContext
            )
        }
    }

    private func removeMark() {
        performHistoryUpdate { selectedDay in
            try ItemOperations.undoMark(
                item,
                on: selectedDay,
                context: modelContext
            )
        }
    }

    private func performHistoryUpdate(
        _ action: (LocalDay) throws -> Void
    ) {
        guard let selectedDay else {
            presentError(message: String(localized: "Choose a valid day no later than today."))
            return
        }

        do {
            try action(selectedDay)
        } catch {
            presentError(message: error.localizedDescription)
        }
    }

    private func presentError(message: String) {
        errorMessage = message
        isPresentingError = true
    }

    private func clearError() {
        errorMessage = ""
        isPresentingError = false
    }

    private func dismissSheet() {
        dismiss()
    }
}
