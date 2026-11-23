import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct MarkDayDetail: View {
    @Environment(\.dismiss)
    private var dismiss
    let day: String
    let items: [Item]

    var body: some View {
        let entries = items.compactMap { item -> (item: Item, count: Int)? in
            guard let count = MarkOperations.countsByDay(for: item, in: day...day)[day] else {
                return nil
            }
            return (item, count)
        }
        let itemsByName = Dictionary(grouping: entries.map(\.item), by: \.name)
        NavigationStack {
            List {
                MHContainerContent {
                    ForEach(entries, id: \.item.persistentModelID) { entry in
                        LabeledContent {
                            Text("\(entry.count) Marks")
                        } label: {
                            VStack(alignment: .leading) {
                                Text(entry.item.name)
                                if let peers = itemsByName[entry.item.name], peers.count > 1 {
                                    distinction(for: entry.item, among: peers)
                                }
                            }
                        }
                    }
                }
            }
            .mhListChrome(.content)
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView("No Marks on This Day", systemImage: "calendar")
                }
            }
            .navigationTitle(RecordDateDraft.display(day))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    StallyActionButton(.done) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func distinction(for item: Item, among peers: [Item]) -> some View {
        if let note = item.note, peers.count(where: { $0.note == note }) == 1 {
            Text(note).mhRowSupporting()
        } else {
            Text(item.uuid.uuidString)
                .mhTextStyle(.caption, colorRole: .secondaryText)
                .monospaced()
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}
