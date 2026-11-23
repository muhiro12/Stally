import StallyLibrary
import SwiftData
import SwiftUI

struct QuickMarkButtons: View {
    @Environment(\.modelContext)
    private var context
    @Environment(RecordWriteSession.self)
    private var writeSession
    @Environment(Item.self)
    private var item
    var inList = false
    @State private var lastAddedID: UUID?
    @State private var saving = false
    @State private var errorMessage: String?

    var body: some View {
        if inList {
            VStack {
                Button {
                    add(includesTime: false)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .frame(
                            minWidth: LibraryLayout.minimumControlSize,
                            minHeight: LibraryLayout.minimumControlSize
                        )
                }
                .accessibilityLabel("Record Today for \(item.name)")
                .disabled(saving || !item.isMarkRecordingEnabled)
                if lastAddedID != nil {
                    Button(action: undo) {
                        Image(systemName: "arrow.uturn.backward")
                            .frame(
                                minWidth: LibraryLayout.minimumControlSize,
                                minHeight: LibraryLayout.minimumControlSize
                            )
                    }
                    .accessibilityLabel("Undo Last Addition for \(item.name)")
                    .disabled(saving)
                }
            }
            .buttonStyle(.borderless)
            .tint(.markActionAccent)
            .alert("Could Not Save", isPresented: showingError) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        } else {
            StallyActionButton(.recordToday) { add(includesTime: false) }
                .disabled(saving || !item.isMarkRecordingEnabled)
            StallyActionButton(.recordNow) { add(includesTime: true) }
                .disabled(saving || !item.isMarkRecordingEnabled)
            if lastAddedID != nil {
                StallyActionButton(.undoAddition, action: undo)
                    .disabled(saving)
            }
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
        }
    }

    private var showingError: Binding<Bool> {
        .init(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func undo() {
        guard let lastAddedID else {
            return
        }
        mutate {
            try MarkOperations.undoAddition(uuid: lastAddedID, context: context)
            self.lastAddedID = nil
        }
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
            defer {
                saving = false
            }
            do {
                try await writeSession.performMutation(operation)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
