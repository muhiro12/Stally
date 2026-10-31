import StallyLibrary
import SwiftData
import SwiftUI

struct QuickMarkButtons: View {
    @Environment(\.modelContext)
    private var context
    @Environment(RemoteUpdateOperations.self)
    private var updates
    let item: Item
    @State private var lastAddedID: UUID?
    @State private var saving = false
    @State private var errorMessage: String?

    var body: some View {
        Button("Record Today", systemImage: "checkmark.circle") { add(includesTime: false) }
            .disabled(saving || !item.isMarkRecordingEnabled)
        Button("Record Now with Time", systemImage: "clock") { add(includesTime: true) }
            .disabled(saving || !item.isMarkRecordingEnabled)
        if let lastAddedID {
            Button("Undo Last Addition", systemImage: "arrow.uturn.backward") {
                mutate {
                    try MarkOperations.undoAddition(uuid: lastAddedID, context: context)
                    self.lastAddedID = nil
                }
            }
            .disabled(saving)
        }
        if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
    }

    private func add(includesTime: Bool) {
        let localDateTime = MarkOperations.localDateTime(at: .now, includesTime: includesTime)
        mutate {
            let mark = try MarkOperations.add(to: item, localDateTime: localDateTime, context: context)
            lastAddedID = mark.uuid
        }
    }

    private func mutate(_ operation: @escaping () throws -> Void) {
        saving = true
        Task {
            defer { saving = false }
            do {
                try await updates.performMutation(operation)
                errorMessage = nil
            } catch { errorMessage = error.localizedDescription }
        }
    }
}
