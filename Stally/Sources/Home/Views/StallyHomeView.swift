import MHDeepLinking
import StallyLibrary
import SwiftData
import SwiftUI
import UIKit

struct StallyHomeView: View {
    @Environment(StallyAppModel.self)
    private var appModel
    @Environment(\.modelContext)
    private var context
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State private var screenModel: StallyHomeScreenModel

    let snapshot: StallyLibrarySnapshot
    let navigationNamespace: Namespace.ID

    var body: some View {
        content
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    settingsButton
                }

                ToolbarItem(placement: .topBarTrailing) {
                    addButton
                }
            }
            .task(id: snapshot.syncKey) {
                screenModel.update(snapshot: snapshot)
            }
            .stallyScreenBackground()
    }

    init(
        snapshot: StallyLibrarySnapshot,
        navigationNamespace: Namespace.ID
    ) {
        self.snapshot = snapshot
        self.navigationNamespace = navigationNamespace
        _screenModel = State(
            initialValue: .init(snapshot: snapshot)
        )
    }
}

private extension StallyHomeView {
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
        if screenModel.snapshot.activeItems.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: StallyDesign.Layout.sectionSpacing) {
                    emptyHero
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
                    heroCarousel
                    browseSection
                    utilityPanels
                }
                .padding(.horizontal, StallyDesign.Layout.screenPadding)
                .padding(.top, 12)
                .safeAreaPadding(.bottom, 28)
            }
            .contentMargins(.bottom, 28, for: .scrollContent)
            .searchable(
                text: querySearchTextBinding,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search items"
            )
        }
    }

    var browseSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            StallySectionHeader(
                eyebrow: "Browse",
                title: "A calm inventory of what still matters",
                subtitle: "Filter the list, then jump straight into today’s action or a deeper look."
            )

            StallyItemQueryControls(
                query: queryBinding,
                displayedCount: screenModel.displayedItems.count,
                usesCompactLayout: usesCompactLayout
            )

            quickFilters

            VStack(alignment: .leading, spacing: 12) {
                StallySectionHeader(
                    eyebrow: nil,
                    title: "Collection snapshot",
                    subtitle: "These numbers update from the current search and filter state."
                )

                StallyMetricGrid(
                    metrics: screenModel.homeSummaryMetrics,
                    usesCompactLayout: usesCompactLayout
                )
            }

            if screenModel.displayedItems.isEmpty {
                filteredEmptyState
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(screenModel.displayedItems, id: \.id) { item in
                        itemCard(item)
                    }
                }
            }
        }
    }

    var heroCarousel: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Today",
                title: "Recently active",
                subtitle: "The items you touched most recently stay surfaced at the top."
            )

            TabView {
                ForEach(screenModel.recentItems, id: \.id) { item in
                    NavigationLink(
                        value: StallyAppModel.StackDestination.item(item.id)
                    ) {
                        heroCard(item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: usesCompactLayout ? StallyDesign.Layout.heroCompactHeight : StallyDesign.Layout.heroHeight)
            .tabViewStyle(.page)
        }
    }

    func heroCard(
        _ item: Item
    ) -> some View {
        let summary = ItemInsightsCalculator.summary(for: item)

        return ZStack(alignment: .bottomLeading) {
            heroArtwork(for: item)
            .overlay {
                RoundedRectangle(
                    cornerRadius: StallyDesign.Radius.panel,
                    style: .continuous
                )
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.black.opacity(0.14),
                            Color.black.opacity(0.56)
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
            }
            .matchedTransitionSource(
                id: item.id,
                in: navigationNamespace
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("RECENTLY ACTIVE")
                    .font(.caption.weight(.bold))
                    .tracking(1.6)
                    .foregroundStyle(StallyDesign.Palette.accentSoft)

                Text(item.name)
                    .font(StallyDesign.Typography.hero)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    StallyTag(
                        title: item.category.title,
                        tone: .quiet
                    )

                    Text("\(summary.totalMarks) marks")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.84))
                }
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity)
        .clipShape(
            RoundedRectangle(
                cornerRadius: StallyDesign.Radius.panel,
                style: .continuous
            )
        )
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

    var utilityPanels: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Paths",
                title: "Jump into the next workflow",
                subtitle: "Review, insight reading, archive cleanup, and backups stay one tap away."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(screenModel.utilityPanels) { panel in
                        utilityCard(
                            title: panel.title,
                            value: panel.value,
                            supporting: panel.supporting,
                            metrics: panel.metrics
                        ) {
                            openUtility(panel.destination)
                        }
                    }
                }
                .padding(.bottom, 4)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }

    func utilityCard(
        title: String,
        value: String,
        supporting: String,
        metrics: [StallyMetricGrid.Metric],
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(StallyDesign.Typography.cardTitle)
                    .foregroundStyle(StallyDesign.Palette.ink)

                Spacer(minLength: 10)

                Text(value)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(StallyDesign.Palette.accent)
            }

            Text(supporting)
                .font(StallyDesign.Typography.caption)
                .foregroundStyle(StallyDesign.Palette.mutedInk)

            StallyMetricGrid(
                metrics: metrics,
                usesCompactLayout: true
            )

            Button("Open") {
                action()
            }
            .buttonStyle(.glassProminent)
            .tint(StallyDesign.Palette.accent)
        }
        .frame(width: 296, alignment: .leading)
        .stallyPanel(.base)
    }

    func itemCard(
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

                        Text(markSupportingText(for: summary))
                            .font(StallyDesign.Typography.caption)
                            .foregroundStyle(StallyDesign.Palette.mutedInk)

                        HStack(spacing: 10) {
                            statPill(
                                title: "Marks",
                                value: "\(summary.totalMarks)"
                            )
                            statPill(
                                title: "Last",
                                value: lastMarkedValue(for: summary)
                            )
                        }
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

            if summary.isMarkedToday {
                Button {
                    appModel.performAction {
                        try StallyAppActionService.toggleTodayMark(
                            context: context,
                            item: item
                        )
                    }
                } label: {
                    Label(
                        "Marked Today",
                        systemImage: "checkmark.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(StallySecondaryButtonStyle())
            } else {
                Button {
                    appModel.performAction {
                        try StallyAppActionService.toggleTodayMark(
                            context: context,
                            item: item
                        )
                    }
                } label: {
                    Label(
                        "Mark Today",
                        systemImage: "circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(StallyPrimaryButtonStyle())
            }
        }
        .stallyPanel(summary.isMarkedToday ? .quiet : .base)
    }

    func statPill(
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(StallyDesign.Palette.mutedInk)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(StallyDesign.Palette.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(StallyDesign.Palette.elevatedSurface)
        )
    }

    var emptyHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("STALLY")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(StallyDesign.Palette.accentSoft)

            Text("Build a quieter ritual around the things you keep choosing.")
                .font(StallyDesign.Typography.hero)
                .foregroundStyle(.white)

            Text("Add the first item, seed sample data, or open backup tools to restore an older collection.")
                .font(StallyDesign.Typography.body)
                .foregroundStyle(.white.opacity(0.82))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .stallyPanel(.accent, padding: 22)
    }

    var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "First steps",
                title: "Nothing is in the library yet",
                subtitle: "Start with one item you reach for often, then mark it once when you chose it today."
            )

            Button("Add Your First Item") {
                appModel.presentCreateEditor()
            }
            .buttonStyle(StallyPrimaryButtonStyle())

            Button("Try Sample Items") {
                appModel.performAction {
                    try StallyAppActionService.seedSampleData(
                        context: context
                    )
                }
            }
            .buttonStyle(StallySecondaryButtonStyle())

            Button("Open Backup Center") {
                appModel.openBackup(in: .library)
            }
            .buttonStyle(StallySecondaryButtonStyle())
        }
        .stallyPanel(.base)
    }

    var filteredEmptyState: some View {
        ContentUnavailableView(
            "No Matching Items",
            systemImage: "line.3.horizontal.decrease.circle",
            description: Text("Try a different search term, category, or quick filter.")
        )
        .frame(maxWidth: .infinity)
        .stallyPanel(.quiet)
    }

    var addButton: some View {
        Button {
            appModel.presentCreateEditor()
        } label: {
            Image(systemName: "plus")
                .font(.headline.weight(.semibold))
        }
        .buttonStyle(.glassProminent)
        .tint(StallyDesign.Palette.accent)
        .matchedTransitionSource(
            id: "create-item",
            in: navigationNamespace
        )
    }

    var settingsButton: some View {
        Button {
            appModel.openSettings(in: .library)
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.headline.weight(.semibold))
                .foregroundStyle(StallyDesign.Palette.ink)
        }
    }

    var usesCompactLayout: Bool {
        horizontalSizeClass != .regular
    }

    func lastMarkedValue(
        for summary: ItemSummary
    ) -> String {
        if let lastMarkedAt = summary.lastMarkedAt {
            return lastMarkedAt.formatted(
                date: .abbreviated,
                time: .omitted
            )
        }

        return StallyLocalization.string("Not yet")
    }

    func markSupportingText(
        for summary: ItemSummary
    ) -> String {
        if summary.isMarkedToday {
            return StallyLocalization.string("Tap again if today should no longer count.")
        }

        return StallyLocalization.string("One mark is enough for today.")
    }

    func itemLinkURL(
        for item: Item
    ) -> URL? {
        StallyDeepLinking.codec().preferredURL(
            for: .item(item.id)
        )
    }

    @ViewBuilder
    func heroArtwork(
        for item: Item
    ) -> some View {
        if let photoData = item.photoData,
           let image = UIImage(data: photoData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: StallyDesign.Radius.panel,
                        style: .continuous
                    )
                )
        } else {
            ZStack {
                RoundedRectangle(
                    cornerRadius: StallyDesign.Radius.panel,
                    style: .continuous
                )
                .fill(
                    LinearGradient(
                        colors: [
                            StallyDesign.artworkCool,
                            StallyDesign.artworkWarm,
                            StallyDesign.Palette.accentSoft
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                Image(systemName: item.category.symbolName)
                    .font(.system(size: 88, weight: .semibold))
                    .foregroundStyle(StallyDesign.Palette.tint.opacity(0.88))
            }
        }
    }

    func openUtility(
        _ destination: StallyHomeScreenModel.UtilityDestination
    ) {
        switch destination {
        case .review:
            appModel.selectedTab = .review
        case .insights:
            appModel.selectedTab = .insights
        case .archive:
            appModel.selectedTab = .archive
        case .backup:
            appModel.openBackup(in: .library)
        }
    }
}

@available(iOS 26.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]
    @Previewable @Namespace var namespace

    NavigationStack {
        StallyHomeView(
            snapshot: StallyLibrarySnapshotBuilder.build(
                items: items,
                reviewPreferences: .init()
            ),
            navigationNamespace: namespace
        )
    }
}

@available(iOS 26.0, *)
#Preview("Empty Home", traits: .modifier(StallyEmptySampleData())) {
    @Previewable @Namespace var namespace

    NavigationStack {
        StallyHomeView(
            snapshot: StallyLibrarySnapshotBuilder.build(
                items: [],
                reviewPreferences: .init()
            ),
            navigationNamespace: namespace
        )
    }
}
