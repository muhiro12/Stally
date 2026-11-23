#if DEBUG
import MHUI
import SwiftUI

#Preview("Lapsed, current iCloud session") {
    StallyICloudSettingsPreview(hasAccess: false, isSelected: true, isConfigured: true)
}

#Preview("Renewed, next-launch sync") {
    StallyICloudSettingsPreview(hasAccess: true, isSelected: true, isConfigured: false)
}

#Preview("Inactive, explicit off") {
    StallyICloudSettingsPreview(hasAccess: false, isSelected: false, isConfigured: false)
}

#Preview("Inactive, saved on, local session") {
    StallyICloudSettingsPreview(hasAccess: false, isSelected: true, isConfigured: false)
}

#Preview("Explicit off, current iCloud session") {
    StallyICloudSettingsPreview(hasAccess: true, isSelected: false, isConfigured: true)
}

private struct StallyICloudSettingsPreview: View {
    let hasAccess: Bool
    @State private var isSelected: Bool
    let isConfigured: Bool

    var body: some View {
        NavigationStack {
            List {
                StallyICloudSettingsSection(
                    hasSubscriptionAccess: hasAccess,
                    isICloudOn: $isSelected,
                    isICloudConfigured: isConfigured
                )
            }
            .mhListChrome(.native)
            .navigationTitle("Settings")
        }
        .mhTheme(.standard)
    }

    init(hasAccess: Bool, isSelected: Bool, isConfigured: Bool) {
        self.hasAccess = hasAccess
        _isSelected = State(initialValue: isSelected)
        self.isConfigured = isConfigured
    }
}
#endif
