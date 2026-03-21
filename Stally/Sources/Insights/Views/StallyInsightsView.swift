// swiftlint:disable closure_body_length file_length type_contents_order
import StallyLibrary
import SwiftData
import SwiftUI
import UIKit

struct StallyInsightsView: View {
    @Environment(StallyAppModel.self)
    private var appModel
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State private var screenModel: StallyInsightsScreenModel

    let snapshot: StallyInsightsSnapshot

    var body: some View {
        @Bindable var appModel = appModel

        ScrollView {
            VStack(alignment: .leading, spacing: StallyDesign.Layout.sectionSpacing) {
                overviewHero
                controlsSection(
                    includeArchivedItems: $appModel.insightsPreferences.includesArchivedItems
                ) { range in
                    withAnimation(StallyDesign.Motion.quick) {
                        appModel.insightsPreferences.defaultRange = range
                    }
                }
                activitySection
                consistencySection
                categorySection
                rankingSection
                rhythmSection
                recommendationsSection
            }
            .padding(.horizontal, StallyDesign.Layout.screenPadding)
            .padding(.top, 12)
            .safeAreaPadding(.bottom, 28)
        }
        .contentMargins(.bottom, 28, for: .scrollContent)
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appModel.openSettings(in: .insights)
                } label: {
                    toolbarIconLabel(
                        "Open Settings",
                        systemImage: "slider.horizontal.3"
                    )
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: snapshot.reportText,
                    subject: Text("Stally Insights")
                ) {
                    toolbarIconLabel(
                        "Share Report",
                        systemImage: "square.and.arrow.up"
                    )
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Copy Report") {
                        UIPasteboard.general.string = snapshot.reportText
                    }
                } label: {
                    toolbarIconLabel(
                        "More Actions",
                        systemImage: "ellipsis.circle"
                    )
                }
            }
        }
        .task(id: snapshot.syncKey) {
            screenModel.update(snapshot: snapshot)
        }
        .stallyScreenBackground()
    }

    init(
        snapshot: StallyInsightsSnapshot
    ) {
        self.snapshot = snapshot
        _screenModel = State(
            initialValue: .init(snapshot: snapshot)
        )
    }
}

private extension StallyInsightsView {
    func toolbarIconLabel(
        _ title: String,
        systemImage: String
    ) -> some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.iconOnly)
            .font(.headline.weight(.semibold))
            .foregroundStyle(StallyDesign.Palette.ink)
    }

    var usesCompactLayout: Bool {
        horizontalSizeClass != .regular
    }

    var overviewHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Range",
                title: snapshot.range.title,
                subtitle: "Read the collection as momentum, consistency, and possible next moves."
            )

            StallyMetricGrid(
                metrics: screenModel.overviewMetrics,
                usesCompactLayout: usesCompactLayout
            )
        }
        .stallyPanel(.accent)
    }

    func controlsSection(
        includeArchivedItems: Binding<Bool>,
        onSelectRange: @escaping (ItemInsightsRange) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Controls",
                title: "Tune the lens",
                subtitle: "Every panel below follows this window and archive scope."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ItemInsightsRange.allCases, id: \.self) { range in
                        Button(range.title) {
                            onSelectRange(range)
                        }
                        .buttonStyle(
                            StallyChipButtonStyle(
                                isSelected: snapshot.range == range
                            )
                        )
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)

            Toggle(
                "Include archived items",
                isOn: includeArchivedItems
            )
            .toggleStyle(.switch)
        }
        .stallyPanel(.base)
    }

    var activitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Activity",
                title: "Daily marks across the selected window",
                subtitle: "The tallest bars show the busiest pockets of usage."
            )

            activityContent
        }
        .stallyPanel(.base)
    }

    @ViewBuilder
    var activityContent: some View {
        if snapshot.activityDays.isEmpty {
            Text("No activity in this window yet.")
                .font(StallyDesign.Typography.caption)
                .foregroundStyle(StallyDesign.Palette.mutedInk)
        } else {
            activityChart

            StallyMetricGrid(
                metrics: screenModel.activityMetrics,
                usesCompactLayout: usesCompactLayout
            )
        }
    }

    var activityChart: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(snapshot.activityDays, id: \.date, content: activityBar)
            }
            .frame(height: 170, alignment: .bottomLeading)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
    }

    func activityBar(
        _ day: CollectionActivityDay
    ) -> some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(activityBarStyle(for: day))
                .frame(
                    width: 10,
                    height: screenModel.barHeight(for: day)
                )

            if screenModel.shouldShowLabel(for: day) {
                Text(day.date, format: .dateTime.month(.abbreviated).day())
                    .font(.caption2)
                    .foregroundStyle(StallyDesign.Palette.mutedInk)
                    .rotationEffect(.degrees(-45))
                    .frame(height: 34)
            } else {
                Color.clear.frame(height: 34)
            }
        }
        .frame(width: 16)
    }

    func activityBarStyle(
        for day: CollectionActivityDay
    ) -> AnyShapeStyle {
        if day.isActive {
            AnyShapeStyle(StallyDesign.heroGradient)
        } else {
            AnyShapeStyle(StallyDesign.Palette.quietSurface)
        }
    }

    var consistencySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Consistency",
                title: "How steady the rhythm feels",
                subtitle: "Streaks, idle gaps, and weekly density describe how dependable this collection feels."
            )

            StallyMetricGrid(
                metrics: screenModel.consistencyMetrics,
                usesCompactLayout: usesCompactLayout
            )
        }
        .stallyPanel(.base)
    }

    var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Categories",
                title: "Where the marks concentrate",
                subtitle: "The share bar shows how much of the range belongs to each category."
            )

            categoryContent
        }
        .stallyPanel(.base)
    }

    @ViewBuilder
    var categoryContent: some View {
        if snapshot.categorySummaries.isEmpty {
            Text("No category activity in this window.")
                .font(StallyDesign.Typography.caption)
                .foregroundStyle(StallyDesign.Palette.mutedInk)
        } else {
            ForEach(snapshot.categorySummaries, id: \.id, content: categoryCard)
        }
    }

    func categoryCard(
        _ summary: CollectionCategorySummary
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(summary.category.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(StallyDesign.Palette.ink)

                Spacer(minLength: 12)

                Text(
                    summary.shareOfMarks.formatted(
                        .percent.precision(.fractionLength(0))
                    )
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(StallyDesign.Palette.accent)
            }

            Capsule(style: .continuous)
                .fill(StallyDesign.Palette.quietSurface)
                .overlay(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(StallyDesign.heroGradient)
                        .frame(width: categoryBarWidth(for: summary))
                }
                .frame(height: 12)

            Text(
                StallyLocalization.format(
                    "%1$lld marks across %2$lld items",
                    summary.totalMarks,
                    summary.uniqueItems
                )
            )
            .font(StallyDesign.Typography.caption)
            .foregroundStyle(StallyDesign.Palette.mutedInk)
        }
        .stallyPanel(.elevated, padding: 14)
    }

    func categoryBarWidth(
        for summary: CollectionCategorySummary
    ) -> CGFloat {
        max(
            CGFloat(summary.shareOfMarks) * 240,
            24
        )
    }

    var rankingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Rankings",
                title: "What is loudest and quietest right now",
                subtitle: "Top items show repeated use; quiet items point to candidates that may need a decision."
            )

            if usesCompactLayout {
                VStack(spacing: 14) {
                    rankingColumn(
                        title: "Most active",
                        rankings: snapshot.topRankings
                    )
                    rankingColumn(
                        title: "Quietest",
                        rankings: snapshot.quietRankings
                    )
                }
            } else {
                HStack(alignment: .top, spacing: 14) {
                    rankingColumn(
                        title: "Most active",
                        rankings: snapshot.topRankings
                    )
                    rankingColumn(
                        title: "Quietest",
                        rankings: snapshot.quietRankings
                    )
                }
            }
        }
        .stallyPanel(.base)
    }

    func rankingColumn(
        title: String,
        rankings: [CollectionItemRanking]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(StallyDesign.Typography.emphasis)
                .foregroundStyle(StallyDesign.Palette.ink)

            rankingContent(rankings: rankings)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func rankingContent(
        rankings: [CollectionItemRanking]
    ) -> some View {
        if rankings.isEmpty {
            Text("Nothing to show here yet.")
                .font(StallyDesign.Typography.caption)
                .foregroundStyle(StallyDesign.Palette.mutedInk)
        } else {
            ForEach(rankings, id: \.id, content: rankingCard)
        }
    }

    @ViewBuilder
    func rankingCard(
        _ ranking: CollectionItemRanking
    ) -> some View {
        if let item = snapshot.itemsByID[ranking.itemID] {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(StallyDesign.Palette.ink)

                        Text(
                            StallyLocalization.format(
                                "%1$lld marks | %2$lld active days",
                                ranking.totalMarksInRange,
                                ranking.activeDaysInRange
                            )
                        )
                        .font(StallyDesign.Typography.caption)
                        .foregroundStyle(StallyDesign.Palette.mutedInk)
                    }

                    Spacer(minLength: 12)

                    Button("Open") {
                        appModel.openItem(
                            ranking.itemID,
                            in: .insights
                        )
                    }
                    .buttonStyle(StallySecondaryButtonStyle())
                }
            }
            .stallyPanel(.elevated, padding: 14)
        }
    }

    var rhythmSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Rhythm",
                title: "Weekday and monthly texture",
                subtitle: "These tiles show whether the collection clusters on certain days or months."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(snapshot.weekdaySummaries, id: \.weekday) { summary in
                        rhythmTile(
                            title: summary.shortTitle,
                            value: "\(summary.markCount)",
                            supporting: summary.shareOfMarks.formatted(
                                .percent.precision(.fractionLength(0))
                            )
                        )
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(snapshot.monthlySummaries, id: \.monthStart) { summary in
                        rhythmTile(
                            title: summary.monthTitle,
                            value: "\(summary.markCount)",
                            supporting: "\(summary.activeDays) active days"
                        )
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
        .stallyPanel(.base)
    }

    func rhythmTile(
        title: String,
        value: String,
        supporting: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(StallyDesign.Palette.ink)

            Text(value)
                .font(.title.weight(.semibold))
                .foregroundStyle(StallyDesign.Palette.accent)

            Text(supporting)
                .font(StallyDesign.Typography.caption)
                .foregroundStyle(StallyDesign.Palette.mutedInk)
        }
        .frame(width: 140, alignment: .leading)
        .stallyPanel(.elevated, padding: 14)
    }

    var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Next moves",
                title: "Suggested follow-ups from the current range",
                subtitle: "Recommendations stay lightweight so you can act without leaving the flow."
            )

            recommendationsContent
        }
        .stallyPanel(.base)
    }

    @ViewBuilder
    var recommendationsContent: some View {
        if snapshot.recommendations.isEmpty {
            Text("No follow-up suggestions right now.")
                .font(StallyDesign.Typography.caption)
                .foregroundStyle(StallyDesign.Palette.mutedInk)
        } else {
            ForEach(
                snapshot.recommendations,
                id: \.title,
                content: recommendationCard
            )
        }
    }

    func recommendationCard(
        _ recommendation: CollectionRecommendation
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(recommendation.title)
                .font(StallyDesign.Typography.cardTitle)
                .foregroundStyle(StallyDesign.Palette.ink)

            Text(recommendation.message)
                .font(StallyDesign.Typography.caption)
                .foregroundStyle(StallyDesign.Palette.mutedInk)

            if let itemID = recommendation.itemIDs.first {
                Button("Open Suggested Item") {
                    appModel.openItem(
                        itemID,
                        in: .insights
                    )
                }
                .buttonStyle(StallySecondaryButtonStyle())
            }
        }
        .stallyPanel(.elevated, padding: 14)
    }
}

@available(iOS 26.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]

    NavigationStack {
        StallyInsightsView(
            snapshot: StallyInsightsSnapshotBuilder.build(
                items: items,
                preferences: .init()
            )
        )
    }
}
// swiftlint:enable closure_body_length file_length type_contents_order
