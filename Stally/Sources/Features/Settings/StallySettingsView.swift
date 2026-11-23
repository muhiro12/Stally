import MHAppRuntime
import MHPlatformCore
import MHPreferencesUI
import MHUI
import StallyLibrary
import SwiftUI

struct StallySettingsView: View {
    private struct AnnouncementSchedule: TimelineSchedule {
        let hasFeed: Bool

        func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnySequence<Date> {
            guard hasFeed else {
                return AnySequence(CollectionOfOne(startDate))
            }
            let seconds = PeriodicTimelineSchedule(from: .init(timeIntervalSince1970: 0), by: 1)
            return AnySequence(seconds.entries(from: startDate, mode: mode))
        }
    }

    let announcementFeed: MHAnnouncementFeed?

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.locale)
    private var locale
    @Environment(MHAppRuntime.self)
    private var runtime
    @Environment(StallyLibrarySession.self)
    private var librarySession
    @AppStorage(\.stallyICloudEnabled)
    private var iCloudEnabled
    @AppStorage(\.stallySubscriptionActive)
    private var subscriptionActive

    private var canEnableSync: Bool {
        runtime.premiumStatus == .active
            || (runtime.premiumStatus == .unknown && subscriptionActive)
    }

    private var policyLinks: some View {
        Group {
            Link("Privacy Policy", destination: URL(string: "https://muhiro12.github.io/Stally/privacy.html")!)
            Link(
                "Terms of Use",
                destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
            )
        }
    }

    private var subscriptionSection: some View {
        Section {
            NavigationLink("Subscription") {
                List {
                    runtime.subscriptionSectionView()
                    policyLinks
                }
                .mhListChrome(.native)
                .navigationTitle("Subscription")
            }
        } header: {
            Text("Subscription")
        } footer: {
            Text("Sync your Stally library across your devices with iCloud.")
        }
    }

    private var aboutSection: some View {
        Section("About Stally") {
            Link("Support", destination: URL(string: "https://muhiro12.github.io/Stally/")!)
            policyLinks
            NavigationLink("Licenses") {
                runtime.licensesView()
            }
        }
    }

    var body: some View {
        NavigationStack {
            TimelineView(AnnouncementSchedule(hasFeed: announcementFeed != nil)) { _ in
                settingsList(at: .now)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    StallyActionButton(.done) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func settingsList(at date: Date) -> some View {
        List {
            announcementSection(at: date)
            StallyICloudSettingsSection(
                hasSubscriptionAccess: canEnableSync,
                isICloudOn: $iCloudEnabled,
                isICloudConfigured: librarySession.isCloudSyncEnabled
            )
            subscriptionSection
            aboutSection
            Section {
                NavigationLink("Advanced") {
                    StallyAdvancedSettingsView()
                }
            }
        }
        .mhListChrome(.native)
    }

    @ViewBuilder
    private func announcementSection(at date: Date) -> some View {
        if let announcementFeed {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            let announcements = announcementFeed.visibleAnnouncements(
                installedVersion: version.flatMap(MHAppVersion.init),
                at: date,
                preferredLanguages: [locale.identifier(.bcp47)] + Locale.preferredLanguages
            )
            if !announcements.isEmpty {
                Section("Announcements") {
                    ForEach(announcements) { announcement in
                        VStack(alignment: .leading) {
                            Text(verbatim: announcement.title)
                                .font(.headline)
                            Text(verbatim: announcement.body)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}

#Preview("Settings") {
    StallySettingsView(announcementFeed: nil)
        .environment(MHAppRuntime(runtimeOnly: .init()))
        .environment(StallyLibrarySession(updates: .init(), observesAccount: false))
        .mhTheme(.standard)
}

#Preview("Published announcement") {
    let json = """
        {"schemaVersion":1,"defaultLanguage":"en","items":[{"id":"sample","localizations":{
          "en":{"title":"Service maintenance","body":"Sync may take longer during maintenance."},
          "ja":{"title":"メンテナンスのお知らせ","body":"メンテナンス中は同期に時間がかかることがあります。"}
        }}]}
        """
    let feed = try? JSONDecoder().decode(MHAnnouncementFeed.self, from: Data(json.utf8))
    StallySettingsView(announcementFeed: feed)
        .environment(MHAppRuntime(runtimeOnly: .init()))
        .environment(StallyLibrarySession(updates: .init(), observesAccount: false))
        .mhTheme(.standard)
}
