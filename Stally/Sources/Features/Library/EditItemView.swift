//
//  EditItemView.swift
//  Stally
//
//  Created by Codex on 2026/07/12.
//

import SwiftData
import SwiftUI

struct EditItemView: View {
    private enum Layout {
        static let noteLineLimit = 3
    }

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.timeZone)
    private var timeZone

    let item: Item

    @State private var name: String
    @State private var category: ItemCategory
    @State private var note: String
    @State private var photoData: Data?
    @State private var isLoadingPhoto = false
    @State private var saveErrorMessage: String?
    @State private var tracking: ItemTrackingFormState

    private var isShowingSaveError: Binding<Bool> {
        .init {
            saveErrorMessage != nil
        } set: { isPresented in
            if !isPresented {
                saveErrorMessage = nil
            }
        }
    }

    private var isSaveDisabled: Bool {
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
                    allowsDisablingMarks: ItemOperations.canDisableMarkRecording(item)
                )
            }
            .stallyFormChrome()
            .navigationTitle("Edit Item")
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
            Button("Save", action: updateItem)
                .stallyToolbarActionStyle()
                .disabled(isSaveDisabled)
        }
    }

    init(item: Item) {
        self.item = item
        _name = .init(initialValue: item.name)
        _category = .init(initialValue: item.category)
        _note = .init(initialValue: item.note)
        _photoData = .init(initialValue: item.photoData)
        _tracking = .init(initialValue: .init(item: item))
    }

    private func updateItem() {
        do {
            let now = Date()
            guard let today = LocalDay(containing: now, in: timeZone) else {
                throw CocoaError(.coderInvalidValue)
            }
            try ItemOperations.update(
                item,
                input: .init(
                    name: name,
                    category: category,
                    note: note,
                    photoData: photoData
                ),
                tracking: try tracking.input(),
                today: today,
                context: modelContext
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
