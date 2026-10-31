import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct TagManagerView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Query(sort: \Tag.name)
    private var tags: [Tag]
    @State private var addingTag = false
    @State private var consolidating = false
    @State private var editingTag: Tag?

    private let minimumConsolidationCount = 2

    var body: some View {
        NavigationStack {
            tagList
                .navigationTitle("Tags")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark") {
                            dismiss()
                        }
                    }
                }
                .sheet(isPresented: $consolidating) { TagConsolidationView() }
                .sheet(isPresented: $addingTag) {
                    TagEditor(tag: nil)
                }
                .sheet(item: $editingTag) { tag in
                    TagEditor(tag: tag)
                }
        }
    }
    private var tagList: some View {
        List {
            MHContainerContent {
                Section {
                    ForEach(tags) { tag in
                        Button {
                            editingTag = tag
                        } label: {
                            HStack {
                                TagNameView(tag: tag, tags: tags)
                                Spacer()
                                Text("\((tag.items ?? []).count) Items")
                                    .mhForegroundStyle(.secondaryText)
                            }
                            .mhForegroundStyle(.primaryText)
                        }
                    }
                    Button("Consolidate Tags") { consolidating = true }.disabled(tags.count < minimumConsolidationCount)
                    Button("Add Tag", systemImage: "plus") {
                        addingTag = true
                    }
                } footer: {
                    MHSectionFooter("Tags with the same name remain separate. Choose the tag you want to use.")
                }
            }
        }
        .mhListChrome(.content)
    }
}
