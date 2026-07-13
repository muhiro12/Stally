import MHPlatformCore

/// App-owned preference descriptors backed by `UserDefaults`.
public extension MHPreferenceDescriptors {
    /// Days before an unmarked item appears in Review.
    var needsFirstMarkAfterDays: MHIntPreferenceDescriptor {
        .init(
            storageKey: StallyUserDefaultsKeys.Standard.needsFirstMarkAfterDays.rawValue,
            defaultSelection: .standard,
            default: ReviewSettings.default.needsFirstMarkAfterDays
        )
    }

    /// Days of inactivity before a marked item appears in Review.
    var dormantAfterDays: MHIntPreferenceDescriptor {
        .init(
            storageKey: StallyUserDefaultsKeys.Standard.dormantAfterDays.rawValue,
            defaultSelection: .standard,
            default: ReviewSettings.default.dormantAfterDays
        )
    }

    /// Whether Review keeps empty, completed lanes visible.
    var showsCompletedReviewSections: MHBoolPreferenceDescriptor {
        .init(
            storageKey: StallyUserDefaultsKeys.Standard.showsCompletedReviewSections.rawValue,
            defaultSelection: .standard,
            default: true
        )
    }

    /// Persisted default range for Insights.
    var defaultInsightsRange: MHStringPreferenceDescriptor {
        .init(
            storageKey: StallyUserDefaultsKeys.Standard.defaultInsightsRange.rawValue,
            defaultSelection: .standard
        )
    }

    /// Whether Insights includes archived items by default.
    var includesArchivedItemsInInsights: MHBoolPreferenceDescriptor {
        .init(
            storageKey: StallyUserDefaultsKeys.Standard.includesArchivedItemsInInsights.rawValue,
            defaultSelection: .standard,
            default: false
        )
    }

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
