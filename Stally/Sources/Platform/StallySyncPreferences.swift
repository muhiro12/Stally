import MHAppRuntime
import Observation
import StallyLibrary

@MainActor
enum StallySyncPreferences {
    static var isEnabled: Bool {
        ICloudSyncOperations.isEnabled()
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
        let access: ICloudSyncOperations.SubscriptionAccess
        switch status {
        case .unknown:
            access = .unknown
        case .active:
            access = .active
        case .inactive:
            access = .inactive
        }
        ICloudSyncOperations.updateSubscriptionAccess(access)
    }
}
