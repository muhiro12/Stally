import StallyLibrary
import SwiftUI

struct ItemMarksSection: View {
    let item: Item
    let edit: (RecordEditor.Selection) -> Void

    private var marks: [ItemMark] {
        (item.marks ?? []).sorted { first, second in
            if first.localDateTime == second.localDateTime {
                return first.createdAt > second.createdAt
            }
            return first.localDateTime > second.localDateTime
        }
    }

    var body: some View {
        Section {
            if marks.isEmpty {
                Label {
                    VStack(alignment: .leading, spacing: LibraryLayout.compactSpacing) {
                        Text("No Marks Yet")
                        Text("Record a moment whenever it matters.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "checkmark.circle").foregroundStyle(.secondary)
                }
                .padding(.vertical, LibraryLayout.rowSpacing)
            }
            ForEach(marks) { mark in
                Button {
                    edit(.mark(mark))
                } label: {
                    HStack {
                        Label(RecordDateDraft.display(mark.localDateTime), systemImage: "checkmark.circle")
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }
                    .foregroundStyle(.primary)
                }
                .accessibilityHint("Edit this Mark")
            }
            Button("Add Mark", systemImage: "plus") {
                edit(.newMark)
            }
            .disabled(!item.isMarkRecordingEnabled)
        } header: {
            Text("Marks")
        } footer: {
            if !item.isMarkRecordingEnabled {
                Text("Recording is paused. You can still edit existing Marks.")
            }
        }
    }
}
