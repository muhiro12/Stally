//
//  AddItemView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

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

    @State private var name = ""
    @State private var category: ItemCategory = .clothing
    @State private var note = ""
    @State private var saveErrorMessage: String?

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
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
        NavigationStack {
            Form {
                AddItemFormFields(
                    name: $name,
                    category: $category,
                    note: $note,
                    noteLineLimit: Layout.noteLineLimit
                )
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: dismissSheet)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: addItem)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .alert("Could Not Save", isPresented: isShowingSaveError) {
                Button("OK", role: .cancel, action: clearSaveError)
            } message: {
                Text(saveErrorMessage ?? "")
            }
        }
    }

    private func addItem() {
        let item = Item(name: trimmedName, category: category, note: trimmedNote)
        modelContext.insert(item)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.delete(item)
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
