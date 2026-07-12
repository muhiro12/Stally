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

    let item: Item

    @State private var name: String
    @State private var category: ItemCategory
    @State private var note: String
    @State private var saveErrorMessage: String?

    private var isShowingSaveError: Binding<Bool> {
        .init {
            saveErrorMessage != nil
        } set: { isPresented in
            if !isPresented {
                saveErrorMessage = nil
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                ItemFormFields(
                    name: $name,
                    category: $category,
                    note: $note,
                    noteLineLimit: Layout.noteLineLimit
                )
            }
            .stallyFormChrome()
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: dismissSheet)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: updateItem)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Could Not Save", isPresented: isShowingSaveError) {
                Button("OK", role: .cancel, action: clearSaveError)
            } message: {
                Text(saveErrorMessage ?? "")
            }
        }
    }

    init(item: Item) {
        self.item = item
        _name = .init(initialValue: item.name)
        _category = .init(initialValue: item.category)
        _note = .init(initialValue: item.note)
    }

    private func updateItem() {
        do {
            try ItemOperations.update(
                item,
                input: .init(
                    name: name,
                    category: category,
                    note: note,
                    photoData: item.photoData
                ),
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
