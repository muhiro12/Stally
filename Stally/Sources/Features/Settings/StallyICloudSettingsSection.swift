import SwiftUI

struct StallyICloudSettingsSection: View {
    let hasSubscriptionAccess: Bool
    @Binding var isICloudOn: Bool
    let isICloudConfigured: Bool

    var body: some View {
        Section {
            Toggle("Use iCloud", isOn: $isICloudOn)
                .disabled(!hasSubscriptionAccess && !isICloudOn)
            if isICloudConfigured {
                Text("iCloud sync is enabled for this session.")
            } else {
                Text("iCloud sync is disabled for this session.")
            }
        } header: {
            Text("iCloud Sync")
        } footer: {
            VStack(alignment: .leading) {
                Text(
                    """
                    iCloud sync requires a subscription. Your choice is saved even when your subscription ends. \
                    Changes apply after you quit and reopen Stally.
                    """
                )
                if !hasSubscriptionAccess, isICloudOn {
                    Text("Your choice is on, but a subscription is required to enable iCloud sync at the next launch.")
                }
                if (hasSubscriptionAccess && isICloudOn) != isICloudConfigured {
                    if isICloudConfigured {
                        Text("Restart Stally to turn off iCloud sync. It remains enabled for this session until then.")
                    } else {
                        Text("Restart Stally to turn on iCloud sync. It remains disabled for this session until then.")
                    }
                    Text("Resuming Stally from the background does not apply this change.")
                }
            }
        }
    }
}
