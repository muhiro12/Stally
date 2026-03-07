//
//  AddItemView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/07.
//

import SwiftData
import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var itemName = ""
    @FocusState private var isNameFieldFocused: Bool

    private var trimmedItemName: String {
        itemName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("対象名") {
                    TextField("たとえば グレーの靴下", text: $itemName)
                        .focused($isNameFieldFocused)
                }
            }
            .navigationTitle("対象を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addItem()
                    }
                    .disabled(trimmedItemName.isEmpty)
                }
            }
            .onAppear {
                isNameFieldFocused = true
            }
        }
    }

    private func addItem() {
        let item = TrackedItem(name: trimmedItemName)
        modelContext.insert(item)
        try? modelContext.save()
        dismiss()
    }
}
