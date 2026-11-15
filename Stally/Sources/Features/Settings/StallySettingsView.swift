import MHAppRuntime
import MHPreferencesUI
import MHUI
import StallyLibrary
import SwiftUI

struct StallySettingsView: View {
    @Environment(\.dismiss)
    private var dismiss
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
        Section("Subscription") {
            Text("Sync your Stally library across your devices with iCloud.")
            NavigationLink("Subscription") {
                List {
                    Section {
                        Text("Sync your Stally library across your devices with iCloud.")
                    }
                    runtime.subscriptionSectionView()
                    policyLinks
                }
                .mhListChrome(.native)
                .navigationTitle("Subscription")
            }
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
            List {
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
}

#Preview("Settings") {
    StallySettingsView()
        .environment(MHAppRuntime(runtimeOnly: .init()))
        .environment(StallyLibrarySession(updates: .init(), observesAccount: false))
        .mhTheme(.standard)
}
