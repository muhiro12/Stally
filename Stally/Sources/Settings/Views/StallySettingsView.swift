import MHAppRuntimeCore
import MHDeepLinking
import StallyLibrary
import SwiftUI
import UIKit

struct StallySettingsView: View {
    @Environment(MHAppRuntime.self)
    private var appRuntime
    @Environment(StallyAppModel.self)
    private var appModel

    @State private var screenModel: StallySettingsScreenModel

    let snapshot: StallySettingsSnapshot

    var body: some View {
        @Bindable var appModel = appModel

        ScrollView {
            VStack(alignment: .leading, spacing: StallyDesign.Layout.sectionSpacing) {
                aboutSection
                backupSection
                reviewPreferencesSection(
                    reviewPreferences: $appModel.reviewPreferences
                )
                insightsPreferencesSection(
                    insightsPreferences: $appModel.insightsPreferences
                )
                guidanceSection
                deepLinksSection
                buildSection
                resourcesSection
            }
            .padding(.horizontal, StallyDesign.Layout.screenPadding)
            .padding(.top, 12)
            .safeAreaPadding(.bottom, 28)
        }
        .contentMargins(.bottom, 28, for: .scrollContent)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .task(id: snapshot.syncKey) {
            screenModel.update(snapshot: snapshot)
        }
        .stallyScreenBackground()
    }

    init(
        snapshot: StallySettingsSnapshot
    ) {
        self.snapshot = snapshot
        _screenModel = State(
            initialValue: .init(snapshot: snapshot)
        )
    }
}

private extension StallySettingsView {
    var aboutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "About",
                title: StallyAppConfiguration.displayName,
                subtitle: StallyAppConfiguration.conceptLine
            )

            Text(StallyAppConfiguration.baselineNote)
                .font(StallyDesign.Typography.body)
                .foregroundStyle(StallyDesign.Palette.mutedInk)
        }
        .stallyPanel(.accent)
    }

    var backupSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Backup",
                title: "Open the dedicated backup workspace",
                subtitle: "Export and restore actions stay grouped so higher-risk operations remain deliberate."
            )

            Button("Open Backup Center") {
                appModel.openBackup()
            }
            .buttonStyle(StallyPrimaryButtonStyle())
        }
        .stallyPanel(.base)
    }

    func reviewPreferencesSection(
        reviewPreferences: Binding<StallyReviewPreferences>
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Review",
                title: "Tune when items need attention",
                subtitle: "These settings update the Review tab and home snapshot immediately."
            )

            Stepper(
                value: reviewPreferences.untouchedGraceDays,
                in: 1...90
            ) {
                Text(
                    StallyLocalization.format(
                        "Needs First Mark after %lld days",
                        reviewPreferences.wrappedValue.untouchedGraceDays
                    )
                )
            }

            Stepper(
                value: reviewPreferences.dormantAfterDays,
                in: 1...180
            ) {
                Text(
                    StallyLocalization.format(
                        "Dormant after %lld days",
                        reviewPreferences.wrappedValue.dormantAfterDays
                    )
                )
            }

            Toggle(
                "Show completed review sections",
                isOn: reviewPreferences.showCompletedSections
            )
        }
        .stallyPanel(.base)
    }

    func insightsPreferencesSection(
        insightsPreferences: Binding<StallyInsightsPreferences>
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Insights",
                title: "Choose the default lens",
                subtitle: "These defaults apply whenever you return to the Insights dashboard."
            )

            Picker(
                "Default range",
                selection: insightsPreferences.defaultRange
            ) {
                ForEach(ItemInsightsRange.allCases, id: \.self) { range in
                    Text(range.title)
                        .tag(range)
                }
            }
            .pickerStyle(.menu)

            Toggle(
                "Include archived items by default",
                isOn: insightsPreferences.includesArchivedItems
            )
        }
        .stallyPanel(.base)
    }

    var guidanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Guidance",
                title: "Replay first-use tips",
                subtitle: "Use this when you want another quiet walkthrough of the main flows."
            )

            Button("Show Tips Again") {
                appModel.performAction {
                    try StallyAppActionService.resetTips()
                }
            }
            .buttonStyle(StallySecondaryButtonStyle())
        }
        .stallyPanel(.base)
    }

    var deepLinksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Links",
                title: "Share or copy app routes",
                subtitle: "Item-specific links still live on item cards and detail screens."
            )

            ForEach(screenModel.deepLinkRows) { row in
                if let routeURL = routeURL(for: row.route) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.title)
                                .font(StallyDesign.Typography.emphasis)
                                .foregroundStyle(StallyDesign.Palette.ink)

                            Text(row.supporting)
                                .font(StallyDesign.Typography.caption)
                                .foregroundStyle(StallyDesign.Palette.mutedInk)
                        }

                        Spacer(minLength: 12)

                        Button("Copy") {
                            UIPasteboard.general.url = routeURL
                        }
                        .buttonStyle(StallySecondaryButtonStyle())

                        ShareLink(item: routeURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(StallySecondaryButtonStyle())
                    }
                    .stallyPanel(.elevated, padding: 14)
                }
            }
        }
        .stallyPanel(.base)
    }

    var buildSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Build",
                title: "Version details",
                subtitle: "Useful when sharing feedback or checking a specific build."
            )

            HStack(spacing: 12) {
                ForEach(screenModel.buildCards) { card in
                    buildValueCard(title: card.title, value: card.value)
                }
            }
        }
        .stallyPanel(.base)
    }

    func buildValueCard(
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(StallyDesign.Palette.mutedInk)

            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(StallyDesign.Palette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .stallyPanel(.elevated, padding: 14)
    }

    @ViewBuilder
    var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StallySectionHeader(
                eyebrow: "Resources",
                title: "Open-source licenses",
                subtitle: "License information is available when the current runtime exposes it."
            )

            if appRuntime.configuration.showsLicenses {
                NavigationLink {
                    appRuntime.licensesView()
                        .navigationTitle("Licenses")
                } label: {
                    Label("Open Source Licenses", systemImage: "doc.text.magnifyingglass")
                }
                .buttonStyle(StallySecondaryButtonStyle())
            } else {
                Text("License information is unavailable for this app configuration.")
                    .font(StallyDesign.Typography.caption)
                    .foregroundStyle(StallyDesign.Palette.mutedInk)
            }
        }
        .stallyPanel(.base)
    }

    func routeURL(
        for route: StallyRoute
    ) -> URL? {
        StallyDeepLinking.codec().preferredURL(for: route)
    }
}

@available(iOS 26.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    NavigationStack {
        StallySettingsView(
            snapshot: StallySettingsSnapshotBuilder.build()
        )
    }
}
