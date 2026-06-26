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
            .stallyFormChrome()
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: dismissSheet)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: addItem)
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

    private func addItem() {
        do {
            try ItemOperations.create(
                context: modelContext,
                input: .init(name: name, category: category, note: note)
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
