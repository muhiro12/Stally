import StallyLibrary
import SwiftData
import SwiftUI

struct StallyArchiveView: View {
    let items: [Item]
    let onOpenItem: (UUID) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                if items.isEmpty {
                    ContentUnavailableView(
                        "No Archived Items",
                        systemImage: "archivebox",
                        description: Text("Archived items will wait here until you move them back into Home.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                    .stallyCardStyle(cornerRadius: 32)
                } else {
                    ForEach(items, id: \.id) { item in
                        archiveCard(item: item)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationTitle("Archive")
        .stallyScreenBackground()
    }
}

private extension StallyArchiveView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Past favorites can stay nearby without crowding the main list.")
                .font(.title3.weight(.semibold))

            Text("Archive keeps older items intact, with their accumulated marks preserved.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .stallyCardStyle(cornerRadius: 32)
    }

    func archiveCard(
        item: Item
    ) -> some View {
        let summary = ItemInsightsCalculator.summary(for: item)

        return Button {
            onOpenItem(item.id)
        } label: {
            HStack(spacing: 16) {
                StallyItemArtworkView(
                    photoData: item.photoData,
                    category: item.category,
                    width: 74,
                    height: 88
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let archivedAt = item.archivedAt {
                        Text("Archived \(archivedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Archived")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(summary.totalMarks) marks saved")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(StallyDesign.accent)
                }

                Spacer(minLength: .zero)

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .stallyCardStyle(cornerRadius: 28)
        }
        .buttonStyle(.plain)
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]

    NavigationStack {
        StallyArchiveView(
            items: ItemInsightsCalculator.archivedItems(from: items),
            onOpenItem: { _ in
                // no-op
            }
        )
    }
}
