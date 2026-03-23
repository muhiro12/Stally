// swiftlint:disable closure_body_length type_contents_order
import MHPlatform
import MHUI
import StallyLibrary
import SwiftData
import SwiftUI
import TipKit
import UIKit

struct StallyInsightsView: View {
    @Environment(StallyAppModel.self)
    private var appModel
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(\.stallyMHUIThemeMetrics)
    private var theme

    @Namespace private var rangeNamespace

    @State private var screenModel: StallyInsightsScreenModel

    let snapshot: StallyInsightsSnapshot

    var body: some View {
        @Bindable var appModel = appModel

        VStack(alignment: .leading, spacing: theme.spacing.group) {
            overviewCard
            controlsSection(
                includeArchivedItems: $appModel.insightsPreferences.includesArchivedItems
            )
            activitySection
            cadenceSection
            categorySection
            rankingSection
            rhythmSection
            recommendationsSection
            pendingSectionsCard
        }
        .mhScreen(
            title: Text("Insights"),
            subtitle: Text("Read the collection as a pattern, not just a list.")
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Settings", systemImage: "gearshape") {
                    appModel.openSettings(in: .insights)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: snapshot.reportText,
                    subject: Text("Stally Insights")
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(Text("Share"))
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Copy Report") {
                        UIPasteboard.general.string = snapshot.reportText
                    }

                    if let insightsURL {
                        Button("Copy Link") {
                            UIPasteboard.general.url = insightsURL
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel(Text("Actions"))
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: snapshot.syncKey) {
            screenModel.update(snapshot: snapshot)
        }
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
    var usesCompactLayout: Bool {
        horizontalSizeClass != .regular
    }

    var selectedRange: ItemInsightsRange {
        snapshot.range
    }

    var insightsURL: URL? {
        StallyDeepLinking.codec().preferredURL(for: .insights)
    }

    var overviewCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            HStack(alignment: .firstTextBaseline) {
                Text("Overview")
                    .mhRowTitle()

                Spacer(minLength: theme.spacing.control)

                Text(selectedRange.title)
                    .mhRowSupporting()
            }

            Text(
                """
                This foundation combines collection-wide activity, streaks, and health metrics.
                The next sections expand this into trends, rankings, and category views.
                """
            )
            .mhRowSupporting()

            StallyMetricGrid(
                metrics: screenModel.overviewMetrics,
                usesCompactLayout: usesCompactLayout
            )
        }
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }

    func controlsSection(
        includeArchivedItems: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("Range")
                .mhRowTitle()

            ScrollView(.horizontal, showsIndicators: false) {
                StallyGlassContainer(spacing: theme.spacing.control) {
                    HStack(spacing: theme.spacing.control) {
                        ForEach(ItemInsightsRange.allCases, id: \.self) { range in
                            Button(range.title) {
                                withAnimation {
                                    appModel.insightsPreferences.defaultRange = range
                                }
                            }
                            .buttonStyle(
                                selectedRange == range
                                    ? .mhPrimary
                                    : .mhSecondary
                            )
                            .stallyGlassEffectID(
                                range,
                                in: rangeNamespace
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .popoverTip(insightsRangeTip, arrowEdge: .top)

            Text("All metrics on this screen follow the selected window.")
                .mhRowSupporting()

            Toggle(
                "Include archived items",
                isOn: includeArchivedItems
            )
        }
        .mhSection(title: Text("Controls"))
    }

    var activitySection: some View {
        StallyInsightsActivitySection(
            days: snapshot.activityDays,
            summary: snapshot.activitySummary,
            usesCompactLayout: usesCompactLayout
        )
    }

    var cadenceSection: some View {
        StallyInsightsCadenceSection(
            streakSummary: snapshot.streakSummary,
            cadenceSummary: snapshot.cadenceSummary,
            usesCompactLayout: usesCompactLayout
        )
    }

    var categorySection: some View {
        StallyInsightsCategorySection(
            summaries: snapshot.categorySummaries
        )
    }

    var rankingSection: some View {
        StallyInsightsRankingSection(
            itemsByID: snapshot.itemsByID,
            topRankings: snapshot.topRankings,
            quietRankings: snapshot.quietRankings,
            usesCompactLayout: usesCompactLayout
        )
    }

    var rhythmSection: some View {
        StallyInsightsRhythmSection(
            weekdaySummaries: snapshot.weekdaySummaries,
            monthlySummaries: snapshot.monthlySummaries,
            usesCompactLayout: usesCompactLayout
        )
    }

    var recommendationsSection: some View {
        StallyInsightsRecommendationsSection(
            recommendations: snapshot.recommendations,
            itemsByID: snapshot.itemsByID
        ) { itemID in
            appModel.openItem(
                itemID,
                in: .insights
            )
        }
    }

    var pendingSectionsCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            Text("More Comparisons Are Coming")
                .mhRowTitle()

            Text(
                StallyLocalization.string(
                    "This space can expand into longer-range comparisons, saved reports, and trend views "
                        + "that look beyond one selected window."
                )
            )
            .mhRowSupporting()
        }
        .mhSurfaceInset()
        .mhSurface()
    }

    var insightsRangeTip: (any Tip)? {
        guard snapshot.itemsByID.isEmpty == false else {
            return nil
        }

        return StallyTips.InsightsRangeTip()
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
// swiftlint:enable closure_body_length type_contents_order
