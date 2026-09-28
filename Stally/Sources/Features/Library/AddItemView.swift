//
//  AddItemView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHUI
import SwiftData
import SwiftUI

struct AddItemView: View {
    private enum Layout {
        static let noteLineLimit = 3
    }

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.timeZone)
    private var timeZone

    @State private var name = ""
    @State private var category: ItemCategory = .clothing
    @State private var note = ""
    @State private var photoData: Data?
    @State private var isLoadingPhoto = false
    @State private var saveErrorMessage: String?
    @State private var tracking = ItemTrackingFormState()

    private var isShowingSaveError: Binding<Bool> {
        Binding {
            saveErrorMessage != nil
        } set: { isPresented in
            if !isPresented {
                saveErrorMessage = nil
            }
        }
    }

    private var isAddDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || isLoadingPhoto || (try? tracking.input()) == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                ItemFormFields(
                    name: $name,
                    category: $category,
                    note: $note,
                    photoData: $photoData,
                    isLoadingPhoto: $isLoadingPhoto,
                    tracking: $tracking,
                    noteLineLimit: Layout.noteLineLimit,
                    allowsDisablingMarks: true
                )
            }
            .stallyFormChrome(.content)
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarItems
            }
            .alert("Could Not Save", isPresented: isShowingSaveError) {
                Button("OK", role: .cancel, action: clearSaveError)
            } message: {
                Text(saveErrorMessage ?? "")
            }
        }
    }

    @ToolbarContentBuilder private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", role: .cancel, action: dismissSheet)
                .stallyToolbarActionStyle()
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("Add", action: addItem)
                .stallyToolbarActionStyle()
                .disabled(isAddDisabled)
        }
    }

    private func addItem() {
        do {
            let now = Date()
            guard let today = LocalDay(containing: now, in: timeZone) else {
                throw CocoaError(.coderInvalidValue)
            }
            try ItemOperations.create(
                context: modelContext,
                input: .init(
                    name: name,
                    category: category,
                    note: note,
                    photoData: photoData
                ),
                tracking: try tracking.input(),
                today: today,
                createdAt: now
            )
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func clearSaveError() {
        saveErrorMessage = nil
    }

    private func dismissSheet() {
        dismiss()
    }
}
