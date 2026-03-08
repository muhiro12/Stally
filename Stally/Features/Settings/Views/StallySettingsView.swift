import MHDeepLinking
import MHPlatform
import MHUI
import StallyLibrary
import SwiftUI
import UIKit

struct StallySettingsView: View {
    private struct DeepLinkRow: Identifiable {
        let title: String
        let route: StallyRoute
        let supporting: String

        var id: String {
            title
        }
    }

    @Environment(MHAppRuntime.self)
    private var appRuntime

    @Binding var reviewPreferences: StallyReviewPreferences
    @Binding var insightsPreferences: StallyInsightsPreferences
    let onOpenBackup: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            aboutSection
            backupSection
            reviewPreferencesSection
            insightsPreferencesSection
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

                        Button("Copy") {
                            UIPasteboard.general.url = routeURL
                        }
                        .buttonStyle(.mhSecondary)

                        ShareLink(item: routeURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.mhSecondary)
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
                Share the app’s main routes directly from Settings.
                Item-specific links remain available from item cards and detail.
                """
            )
        )
    }

    var reviewPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper(
                "Needs First Mark after \(reviewPreferences.untouchedGraceDays) days",
                value: $reviewPreferences.untouchedGraceDays,
                in: 1...90
            )

            Stepper(
                "Dormant after \(reviewPreferences.dormantAfterDays) days",
                value: $reviewPreferences.dormantAfterDays,
                in: 1...180
            )

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
            ?? "Unknown"
    }

    var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
            ?? "Unknown"
    }

    private var deepLinkRows: [DeepLinkRow] {
        [
            .init(
                title: "Home",
                route: .home,
                supporting: "Open the main collection view."
            ),
            .init(
                title: "Archive",
                route: .archive,
                supporting: "Jump straight to archived items."
            ),
            .init(
                title: "Backup Center",
                route: .backup,
                supporting: "Open backup and restore tools."
            ),
            .init(
                title: "Review",
                route: .review,
                supporting: "Open the review workflow."
            ),
            .init(
                title: "Create Item",
                route: .createItem,
                supporting: "Start a new item from a link."
            ),
            .init(
                title: "Settings",
                route: .settings,
                supporting: "Open Settings directly."
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
        }
    }
}
