import MHDeepLinking
import MHPlatform
import MHUI
import StallyLibrary
import SwiftUI
import UIKit

struct StallySettingsView: View {
    @Environment(MHAppRuntime.self)
    private var appRuntime

    @Binding var reviewPreferences: StallyReviewPreferences
    let onOpenBackup: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            aboutSection
            backupSection
            reviewPreferencesSection
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
            supporting: Text("Export and restore tools live in a separate workspace so higher-risk actions stay grouped together.")
        )
    }

    var deepLinkUtilitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(deepLinkRows, id: \.title) { row in
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
            supporting: Text("Share the app’s main routes directly from Settings. Item-specific links remain available from item cards and detail.")
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

    var deepLinkRows: [(title: String, route: StallyRoute, supporting: String)] {
        [
            ("Home", .home, "Open the main collection view."),
            ("Archive", .archive, "Jump straight to archived items."),
            ("Backup Center", .backup, "Open backup and restore tools."),
            ("Review", .review, "Open the review workflow."),
            ("Create Item", .createItem, "Start a new item from a link."),
            ("Settings", .settings, "Open Settings directly.")
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

    NavigationStack {
        StallySettingsView(
            reviewPreferences: $reviewPreferences,
            onOpenBackup: {}
        )
    }
}
