import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct ItemDraftTagsSection: View {
    @Binding var draft: ItemDraft
    @Query(sort: \Tag.name)
    private var tags: [Tag]
    @State private var newTagName = ""

    var body: some View {
        Section {
            ForEach(tags) { tag in
                Toggle(isOn: binding(for: tag)) {
                    TagNameView(tag: tag, tags: tags)
                }
            }
            ForEach(draft.newTags) { tag in
                HStack {
                    Text(tag.name)
                    Spacer()
                    Button(role: .destructive) {
                        draft.newTags.removeAll { $0.id == tag.id }
                    } label: {
                        actionLabel("Remove Tag", systemImage: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                }
            }
            HStack {
                TextField("New Tag", text: $newTagName)
                Button {
                    draft.newTags.append(.init(name: newTagName))
                    newTagName = ""
                } label: {
                    actionLabel("Add Tag", systemImage: "plus")
                }
                .buttonStyle(.borderless)
                .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } header: {
            MHSectionHeader("Tags")
        }
    }

    private func actionLabel(_ title: LocalizedStringKey, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.iconOnly)
            .frame(minWidth: LibraryLayout.minimumControlSize, minHeight: LibraryLayout.minimumControlSize)
            .contentShape(.rect)
    }

    private func binding(for tag: Tag) -> Binding<Bool> {
        .init(
            get: { draft.tagIDs.contains(tag.uuid) },
            set: { selected in
                if selected {
                    draft.tagIDs.insert(tag.uuid)
                } else {
                    draft.tagIDs.remove(tag.uuid)
                }
            }
        )
    }
}
