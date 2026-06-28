import MHPlatformCore

/// App-owned preference descriptors backed by `UserDefaults`.
public extension MHPreferenceDescriptors {
    /// Subscription state persisted in the standard defaults domain.
    var isSubscribeOn: MHBoolPreferenceDescriptor {
        .init(
            storageKey: StallyUserDefaultsKeys.Standard.isSubscribeOn.rawValue,
            defaultSelection: .standard,
            default: false
        )
    }

    /// iCloud sync preference persisted in the standard defaults domain.
    var isICloudOn: MHBoolPreferenceDescriptor {
        .init(
            storageKey: StallyUserDefaultsKeys.Standard.isICloudOn.rawValue,
            defaultSelection: .standard,
            default: false
        )
    }
}
