import MHPlatform
import MHUI
import SwiftUI

struct StallySettingsView: View {
    @Environment(MHAppRuntime.self)
    private var appRuntime

    @Binding var reviewPreferences: StallyReviewPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            aboutSection
            reviewPreferencesSection
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
}

#Preview {
    @Previewable @State var reviewPreferences = StallyReviewPreferences()

    NavigationStack {
        StallySettingsView(reviewPreferences: $reviewPreferences)
    }
}
