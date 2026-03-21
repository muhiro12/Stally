import MHDeepLinking
import MHAppRuntimeCore
import MHUI
import StallyLibrary
import SwiftUI
import UIKit

private enum StallySettingsDeepLinkRowID: String, Sendable {
    case home
    case archive
    case backup
    case insights
    case review
    case createItem
    case settings
}

struct StallySettingsView: View {
    private struct DeepLinkRow: Identifiable {
        let id: StallySettingsDeepLinkRowID
        let title: String
        let route: StallyRoute
        let supporting: String
    }

    @Environment(MHAppRuntime.self)
    private var appRuntime

    @Namespace private var deepLinkActionNamespace

    @Binding var reviewPreferences: StallyReviewPreferences
    @Binding var insightsPreferences: StallyInsightsPreferences
    let onOpenBackup: () -> Void
    let onResetTips: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            aboutSection
            backupSection
            reviewPreferencesSection
            insightsPreferencesSection
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
            LabeledContent("Version", value: appVersion)
                .labeledContentStyle(.mhKeyValue)
            LabeledContent("Build", value: buildNumber)
                .labeledContentStyle(.mhKeyValue)
        }
        .mhSection(title: Text("Build"))
    }

    var backupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Open the dedicated backup workspace before you export or restore anything.")
                .mhRowSupporting()

            Button("Open Backup Center", systemImage: "externaldrive.badge.icloud") {
                onOpenBackup()
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

    var deepLinkUtilitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(deepLinkRows) { row in
                if let routeURL = routeURL(for: row.route) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.title)
                                .mhRowTitle()

                            Text(row.supporting)
                                .mhRowSupporting()
                        }

                        Spacer(minLength: 12)

                        MHGlassContainer(spacing: 12) {
                            HStack(spacing: 12) {
                                Button("Copy") {
                                    UIPasteboard.general.url = routeURL
                                }
                                .buttonStyle(.mhSecondary)
                                .mhGlassEffectID(
                                    "\(row.id.rawValue)-copy",
                                    in: deepLinkActionNamespace
                                )

                                ShareLink(item: routeURL) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.mhSecondary)
                                .mhGlassEffectID(
                                    "\(row.id.rawValue)-share",
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

    var reviewPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper(value: $reviewPreferences.untouchedGraceDays, in: 1...90) {
                Text(
                    StallyLocalization.format(
                        "Needs First Mark after %lld days",
                        reviewPreferences.untouchedGraceDays
                    )
                )
            }

            Stepper(value: $reviewPreferences.dormantAfterDays, in: 1...180) {
                Text(
                    StallyLocalization.format(
                        "Dormant after %lld days",
                        reviewPreferences.dormantAfterDays
                    )
                )
            }

            Toggle(
                "Show completed review sections",
                isOn: $reviewPreferences.showCompletedSections
            )

            Text("These settings update Home and Review immediately.")
                .mhRowSupporting()
        }
        .mhSection(
            title: Text("Review Preferences"),
            supporting: Text("Tune when items become review candidates and whether empty lanes stay visible.")
        )
    }

    var insightsPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker(
                "Default range",
                selection: $insightsPreferences.defaultRange
            ) {
                ForEach(ItemInsightsRange.allCases, id: \.self) { range in
                    Text(range.title)
                        .tag(range)
                }
            }
            .pickerStyle(.menu)

            Toggle(
                "Include archived items by default",
                isOn: $insightsPreferences.includesArchivedItems
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
                onResetTips()
            }
            .buttonStyle(.mhSecondary)
        }
        .mhSection(
            title: Text("Guidance"),
            supporting: Text("Replay the first-use tips if you want another quiet walkthrough of the main flows.")
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

    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? StallyLocalization.string("Unknown")
    }

    var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
            ?? StallyLocalization.string("Unknown")
    }

    private var deepLinkRows: [DeepLinkRow] {
        [
            .init(
                id: .home,
                title: StallyLocalization.string("Home"),
                route: .home,
                supporting: StallyLocalization.string("Open the main collection view.")
            ),
            .init(
                id: .archive,
                title: StallyLocalization.string("Archive"),
                route: .archive,
                supporting: StallyLocalization.string("Jump straight to archived items.")
            ),
            .init(
                id: .backup,
                title: StallyLocalization.string("Backup Center"),
                route: .backup,
                supporting: StallyLocalization.string("Open backup and restore tools.")
            ),
            .init(
                id: .insights,
                title: StallyLocalization.string("Insights"),
                route: .insights,
                supporting: StallyLocalization.string("Open collection analytics and reports.")
            ),
            .init(
                id: .review,
                title: StallyLocalization.string("Review"),
                route: .review,
                supporting: StallyLocalization.string("Open the review workflow.")
            ),
            .init(
                id: .createItem,
                title: StallyLocalization.string("Create Item"),
                route: .createItem,
                supporting: StallyLocalization.string("Start a new item from a link.")
            ),
            .init(
                id: .settings,
                title: StallyLocalization.string("Settings"),
                route: .settings,
                supporting: StallyLocalization.string("Open Settings directly.")
            )
        ]
    }

    func routeURL(
        for route: StallyRoute
    ) -> URL? {
        StallyDeepLinking.codec().preferredURL(for: route)
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(StallySampleData())) {
    @Previewable @State var reviewPreferences = StallyReviewPreferences()
    @Previewable @State var insightsPreferences = StallyInsightsPreferences()

    NavigationStack {
        StallySettingsView(
            reviewPreferences: $reviewPreferences,
            insightsPreferences: $insightsPreferences
        ) {
            // no-op
        } onResetTips: {
            // no-op
        }
    }
}
