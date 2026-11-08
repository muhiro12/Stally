import MHAppRuntime
import MHPlatformCore
import Observation
import StallyLibrary

@MainActor
enum StallySyncPreferences {
    static var isEnabled: Bool {
        let store = MHPreferenceStore()
        return store.bool(for: \.stallyICloudEnabled) && store.bool(for: \.stallySubscriptionActive)
    }

    static func observe(_ runtime: MHAppRuntime) {
        let status = withObservationTracking {
            runtime.premiumStatus
        } onChange: {
            Task { @MainActor in
                observe(runtime)
            }
        }
        record(status)
    }

    private static func record(_ status: MHPremiumStatus) {
        let store = MHPreferenceStore()
        switch status {
        case .unknown:
            return
        case .active:
            store.set(true, for: \.stallySubscriptionActive)
        case .inactive:
            store.set(false, for: \.stallySubscriptionActive)
            store.set(false, for: \.stallyICloudEnabled)
        }
    }
}

extension MHPreferenceDescriptors {
    var stallyICloudEnabled: MHBoolPreferenceDescriptor {
        .init(
            storageKey: "stally.sync.iCloudEnabled",
            defaultSelection: .suite(StallyModelContainerFactory.appGroupIdentifier),
            default: false
        )
    }

    var stallySubscriptionActive: MHBoolPreferenceDescriptor {
        .init(
            storageKey: "stally.subscription.isActive",
            defaultSelection: .suite(StallyModelContainerFactory.appGroupIdentifier),
            default: false
        )
    }
}
