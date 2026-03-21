import MHDeepLinking
import StallyLibrary
import SwiftData
import SwiftUI
import UIKit

struct StallyArchiveView: View {
    @Environment(StallyAppModel.self)
    private var appModel
    @Environment(\.modelContext)
    private var context
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State private var screenModel: StallyArchiveScreenModel

    let snapshot: StallyArchiveSnapshot
    let navigationNamespace: Namespace.ID

    var body: some View {
        content
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appModel.openSettings(in: .archive)
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(StallyDesign.Palette.ink)
                    }
                }
            }
            .task(id: snapshot.syncKey) {
                screenModel.update(snapshot: snapshot)
            }
            .stallyScreenBackground()
    }

    init(
        snapshot: StallyArchiveSnapshot,
        navigationNamespace: Namespace.ID
    ) {
        self.snapshot = snapshot
        self.navigationNamespace = navigationNamespace
        _screenModel = State(
            initialValue: .init(snapshot: snapshot)
        )
    }
}

private extension StallyArchiveView {
    var queryBinding: Binding<ItemListQuery> {
        .init(
            get: {
                screenModel.query
            },
            set: { newValue in
                screenModel.query = newValue
            }
        )
    }

    var querySearchTextBinding: Binding<String> {
        .init(
            get: {
                screenModel.query.searchText
            },
            set: { newValue in
                screenModel.query.searchText = newValue
            }
        )
    }

    @ViewBuilder
    var content: some View {
        if screenModel.snapshot.archivedItems.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: StallyDesign.Layout.sectionSpacing) {
                    archiveHero
                    emptyState
                }
                .padding(.horizontal, StallyDesign.Layout.screenPadding)
                .padding(.top, 12)
                .safeAreaPadding(.bottom, 28)
            }
            .contentMargins(.bottom, 28, for: .scrollContent)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: StallyDesign.Layout.sectionSpacing) {
                    archiveHero
                    browseSection
                }
                .padding(.horizontal, StallyDesign.Layout.screenPadding)
                .padding(.top, 12)
                .safeAreaPadding(.bottom, 28)
            }
            .contentMargins(.bottom, 28, for: .scrollContent)
            .searchable(
                text: querySearchTextBinding,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search archive"
            )
        }
    }

    var archiveHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Preserved",
                title: "Items that stepped out of the daily rotation",
                subtitle: "Archive keeps the history intact while making space for what still feels current."
            )

            StallyMetricGrid(
                metrics: screenModel.archiveMetrics,
                usesCompactLayout: usesCompactLayout
            )
        }
        .stallyPanel(.base)
    }

    var browseSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            StallySectionHeader(
                eyebrow: "Browse",
                title: "Search what you have preserved",
                subtitle: "Filter by history or sort differently before opening an item again."
            )

            StallyItemQueryControls(
                query: queryBinding,
                displayedCount: screenModel.displayedItems.count,
                usesCompactLayout: usesCompactLayout
            )

            quickFilters

            if screenModel.displayedItems.isEmpty {
                filteredEmptyState
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(screenModel.displayedItems, id: \.id) { item in
                        archiveCard(item)
                    }
                }
            }
        }
    }

    var quickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(screenModel.availableQuickFilters) { option in
                    Button(option.title) {
                        withAnimation(StallyDesign.Motion.quick) {
                            screenModel.selectQuickFilter(option.filter)
                        }
                    }
                    .buttonStyle(
                        StallyChipButtonStyle(
                            isSelected: option.filter == screenModel.query.quickFilter
                        )
                    )
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
    }

    func archiveCard(
        _ item: Item
    ) -> some View {
        let summary = ItemInsightsCalculator.summary(for: item)

        return VStack(alignment: .leading, spacing: 14) {
            NavigationLink(
                value: StallyAppModel.StackDestination.item(item.id)
            ) {
                HStack(alignment: .top, spacing: 16) {
                    StallyItemArtworkView(
                        photoData: item.photoData,
                        category: item.category,
                        width: 88,
                        height: 108
                    )
                    .matchedTransitionSource(
                        id: item.id,
                        in: navigationNamespace
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text(item.name)
                            .font(StallyDesign.Typography.cardTitle)
                            .foregroundStyle(StallyDesign.Palette.ink)

                        StallyTag(
                            title: item.category.title,
                            tone: .elevated
                        )

                        Text(
                            StallyLocalization.format(
                                "%1$lld marks kept | archived %@",
                                summary.totalMarks,
                                item.updatedAt.formatted(
                                    date: .abbreviated,
                                    time: .omitted
                                )
                            )
                        )
                        .font(StallyDesign.Typography.caption)
                        .foregroundStyle(StallyDesign.Palette.mutedInk)
                    }

                    Spacer(minLength: .zero)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .contextMenu {
                if let itemLinkURL = itemLinkURL(for: item) {
                    Button("Copy Item Link", systemImage: "link") {
                        UIPasteboard.general.url = itemLinkURL
                    }
                }
            }

            Button {
                appModel.performAction {
                    try StallyAppActionService.unarchive(
                        context: context,
                        item: item
                    )
                }
            } label: {
                Label(
                    "Move Back to Library",
                    systemImage: "tray.and.arrow.up.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(StallySecondaryButtonStyle())
        }
        .stallyPanel(.base)
    }

    var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Empty",
                title: "Nothing has been archived yet",
                subtitle: "Items moved out of the active library will wait here with their mark history intact."
            )

            Button("Open Library") {
                appModel.selectedTab = .library
            }
            .buttonStyle(StallyPrimaryButtonStyle())
        }
        .stallyPanel(.quiet)
    }

    var filteredEmptyState: some View {
        ContentUnavailableView(
            "No Matching Archived Items",
            systemImage: "line.3.horizontal.decrease.circle",
            description: Text("Try a different search term or history filter.")
        )
        .frame(maxWidth: .infinity)
        .stallyPanel(.quiet)
    }

    var usesCompactLayout: Bool {
        horizontalSizeClass != .regular
    }

    func itemLinkURL(
        for item: Item
    ) -> URL? {
        StallyDeepLinking.codec().preferredURL(
            for: .item(item.id)
        )
    }
}

@available(iOS 26.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]
    @Previewable @Namespace var namespace

    NavigationStack {
        StallyArchiveView(
            snapshot: StallyArchiveSnapshotBuilder.build(
                items: items
            ),
            navigationNamespace: namespace
        )
    }
}
