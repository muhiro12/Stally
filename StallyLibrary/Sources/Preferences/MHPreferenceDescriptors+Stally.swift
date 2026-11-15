import MHPlatformCore

public extension MHPreferenceDescriptors {
    /// The person's sync choice, retained across subscription lapses.
    var stallyICloudEnabled: MHBoolPreferenceDescriptor {
        .init(
            storageKey: "stally.sync.iCloudEnabled",
            defaultSelection: .suite(StallyModelContainerFactory.appGroupIdentifier),
            default: false
        )
    }

    /// Last resolved entitlement used at startup while verification is pending.
    var stallySubscriptionActive: MHBoolPreferenceDescriptor {
        .init(
            storageKey: "stally.subscription.isActive",
            defaultSelection: .suite(StallyModelContainerFactory.appGroupIdentifier),
            default: false
        )
    }
}
