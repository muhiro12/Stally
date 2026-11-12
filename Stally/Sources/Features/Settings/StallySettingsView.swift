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

    private var syncSection: some View {
        Section {
            Toggle("Use iCloud", isOn: $iCloudEnabled)
                .disabled(!canEnableSync)
            if librarySession.isCloudSyncEnabled {
                Text("This session uses iCloud sync.")
            } else {
                Text("This session saves on this device.")
            }
        } header: {
            Text("iCloud Sync")
        } footer: {
            Text(
                """
                iCloud sync requires a subscription. Changes take effect the next time Stally launches. \
                Changing this setting does not delete your records.
                """
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
                syncSection
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
                    Button("Done", systemImage: "checkmark") {
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
