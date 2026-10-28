import MHUI
import StallyLibrary
import SwiftUI

struct ItemMarksSection: View {
    @Environment(\.mhTheme)
    private var theme
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
                    VStack(alignment: .leading, spacing: theme.spacing.inline) {
                        Text("No Marks Yet").mhRowTitle()
                        Text("Record a moment whenever it matters.")
                            .mhRowSupporting()
                    }
                } icon: {
                    Image(systemName: "checkmark.circle").mhForegroundStyle(.secondaryText)
                }
            }
            ForEach(marks) { mark in
                markButton(mark)
            }
            Button("Add Mark", systemImage: "plus") {
                edit(.newMark)
            }
            .disabled(!item.isMarkRecordingEnabled)
        } header: {
            MHSectionHeader("Marks")
        } footer: {
            if !item.isMarkRecordingEnabled {
                MHSectionFooter("Recording is paused. You can still edit existing Marks.")
            }
        }
    }

    private func markButton(_ mark: ItemMark) -> some View {
        Button {
            edit(.mark(mark))
        } label: {
            HStack {
                Label(RecordDateDraft.display(mark.localDateTime), systemImage: "checkmark.circle")
                    .mhTextStyle(.body)
                Spacer()
                Image(systemName: "chevron.right").mhTextStyle(.caption, colorRole: .tertiaryText)
            }
            .mhForegroundStyle(.primaryText)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Edit this Mark")
    }
}
