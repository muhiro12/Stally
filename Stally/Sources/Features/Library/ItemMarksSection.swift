import MHUI
import StallyLibrary
import SwiftUI

struct ItemMarksSection: View {
    @Environment(\.mhTheme)
    private var theme
    @Environment(Item.self)
    private var item
    let edit: (RecordEditor.Selection) -> Void

    private var marks: [ItemMark] {
        MarkOperations.orderedMarks(for: item)
    }

    private var actionTheme: MHTheme {
        var markTheme = theme
        markTheme.colors.accent = .asset(.markActionAccent)
        return markTheme
    }

    var body: some View {
        Section {
            QuickMarkButtons()
            StallyActionButton(.addMark) {
                edit(.newMark)
            }
            .disabled(!item.isMarkRecordingEnabled)
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
        } header: {
            MHSectionHeader("Marks")
        } footer: {
            if !item.isMarkRecordingEnabled {
                MHSectionFooter("Recording is paused. You can still edit existing Marks.")
            }
        }
        .mhTheme(actionTheme)
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
