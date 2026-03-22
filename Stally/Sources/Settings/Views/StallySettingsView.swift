// swiftlint:disable closure_body_length type_contents_order
import MHAppRuntimeCore
import MHDeepLinking
import MHUI
import StallyLibrary
import SwiftUI
import UIKit

struct StallySettingsView: View {
    @Environment(MHAppRuntime.self)
    private var appRuntime
    @Environment(StallyAppModel.self)
    private var appModel

    @Namespace private var deepLinkActionNamespace

    @State private var screenModel: StallySettingsScreenModel

    let snapshot: StallySettingsSnapshot

    var body: some View {
        @Bindable var appModel = appModel

        VStack(alignment: .leading, spacing: 24) {
            aboutSection
            backupSection
            reviewPreferencesSection(
                reviewPreferences: $appModel.reviewPreferences
            )
            insightsPreferencesSection(
                insightsPreferences: $appModel.insightsPreferences
            )
            guidanceSection
            deepLinkUtilitiesSection
            buildSection
            resourcesSection
        }
        .mhScreen(
            title: Text("Settings"),
            subtitle: Text("A few quiet details about the app and its build.")
        )
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: snapshot.syncKey) {
            screenModel.update(snapshot: snapshot)
        }
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
        VStack(alignment: .leading, spacing: 12) {
            Text(StallyAppConfiguration.displayName)
                .font(.system(size: 28, weight: .semibold, design: .serif))

            Text(StallyAppConfiguration.conceptLine)
                .mhRowTitle()

            Text(StallyAppConfiguration.baselineNote)
                .mhRowSupporting()
        }
        .mhSection(title: Text("About"))
    }

    var buildSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledContent("Version", value: snapshot.appVersion)
                .labeledContentStyle(.mhKeyValue)
            LabeledContent("Build", value: snapshot.buildNumber)
                .labeledContentStyle(.mhKeyValue)
        }
        .mhSection(title: Text("Build"))
    }

    var backupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Open the dedicated backup workspace before you export or restore anything.")
                .mhRowSupporting()

            Button("Open Backup Center", systemImage: "externaldrive.badge.icloud") {
                appModel.openBackup()
            }
            .buttonStyle(.mhSecondary)
        }
        .mhSection(
            title: Text("Backup"),
            supporting: Text(
                "Export and restore tools live in a separate workspace so higher-risk actions stay grouped together."
            )
        )
    }

    func reviewPreferencesSection(
        reviewPreferences: Binding<StallyReviewPreferences>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper(value: reviewPreferences.untouchedGraceDays, in: 1...90) {
                Text(
                    StallyLocalization.format(
                        "Needs First Mark after %lld days",
                        reviewPreferences.wrappedValue.untouchedGraceDays
                    )
                )
            }

            Stepper(value: reviewPreferences.dormantAfterDays, in: 1...180) {
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

            Text("These settings update Library and Review immediately.")
                .mhRowSupporting()
        }
        .mhSection(
            title: Text("Review Preferences"),
            supporting: Text("Tune when items become review candidates and whether empty lanes stay visible.")
        )
    }

    func insightsPreferencesSection(
        insightsPreferences: Binding<StallyInsightsPreferences>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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

            Text("These defaults apply each time you open Insights.")
                .mhRowSupporting()
        }
        .mhSection(
            title: Text("Insights Preferences"),
            supporting: Text("Choose the default time window and scope for Insights.")
        )
    }

    var guidanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tips appear again when the related screen and state become relevant.")
                .mhRowSupporting()

            Button("Show Tips Again", systemImage: "lightbulb") {
                appModel.performAction {
                    try StallyAppActionService.resetTips()
                }
            }
            .buttonStyle(.mhSecondary)
        }
        .mhSection(
            title: Text("Guidance"),
            supporting: Text("Replay the first-use tips if you want another quiet walkthrough of the main flows.")
        )
    }

    var deepLinkUtilitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(screenModel.deepLinkRows) { row in
                if let routeURL = routeURL(for: row.route) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.title)
                                .mhRowTitle()

                            Text(row.supporting)
                                .mhRowSupporting()
                        }

                        Spacer(minLength: 12)

                        StallyGlassContainer(spacing: 12) {
                            HStack(spacing: 12) {
                                Button("Copy") {
                                    UIPasteboard.general.url = routeURL
                                }
                                .buttonStyle(.mhSecondary)
                                .stallyGlassEffectID(
                                    "\(row.id)-copy",
                                    in: deepLinkActionNamespace
                                )

                                ShareLink(item: routeURL) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.mhSecondary)
                                .stallyGlassEffectID(
                                    "\(row.id)-share",
                                    in: deepLinkActionNamespace
                                )
                            }
                        }
                    }
                }
            }

            Text("Unsupported links now show an alert when Stally cannot parse them.")
                .mhRowSupporting()
        }
        .mhSection(
            title: Text("Deep Links"),
            supporting: Text(
                """
                Share the app's main routes directly from Settings.
                Item-specific links remain available from item cards and detail.
                """
            )
        )
    }

    @ViewBuilder
    var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if appRuntime.configuration.showsLicenses {
                NavigationLink {
                    appRuntime.licensesView()
                        .navigationTitle("Licenses")
                } label: {
                    Label("Open Source Licenses", systemImage: "doc.text.magnifyingglass")
                }
                .buttonStyle(.plain)
            } else {
                Text("License information is unavailable for this app configuration.")
                    .mhRowSupporting()
            }
        }
        .mhSection(title: Text("Resources"))
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
// swiftlint:enable closure_body_length type_contents_order
