import Foundation
import MHPlatformCore
import Testing

@testable import StallyLibrary

struct ICloudSyncOperationsTests {
    @Test(arguments: [false, true])
    func lapseAndRenewalPreserveTheChoiceAcrossPreferenceReloads(isICloudOn: Bool) throws {
        try withStore { suiteName, store in
            store.set(isICloudOn, for: \.stallyICloudEnabled)
            ICloudSyncOperations.updateSubscriptionAccess(.active, store: store)
            #expect(ICloudSyncOperations.isEnabled(store: store) == isICloudOn)

            ICloudSyncOperations.updateSubscriptionAccess(.inactive, store: store)
            let reloaded = MHPreferenceStore(userDefaults: try #require(UserDefaults(suiteName: suiteName)))
            #expect(!ICloudSyncOperations.isEnabled(store: reloaded))
            #expect(reloaded.bool(for: \.stallyICloudEnabled) == isICloudOn)

            ICloudSyncOperations.updateSubscriptionAccess(.active, store: reloaded)
            #expect(ICloudSyncOperations.isEnabled(store: reloaded) == isICloudOn)
            #expect(reloaded.bool(for: \.stallyICloudEnabled) == isICloudOn)
        }
    }

    @Test(arguments: [false, true], [false, true])
    func unknownStatusPreservesAccessAndChoice(isActive: Bool, isICloudOn: Bool) throws {
        try withStore { _, store in
            store.set(isActive, for: \.stallySubscriptionActive)
            store.set(isICloudOn, for: \.stallyICloudEnabled)
            ICloudSyncOperations.updateSubscriptionAccess(.unknown, store: store)
            #expect(store.bool(for: \.stallySubscriptionActive) == isActive)
            #expect(store.bool(for: \.stallyICloudEnabled) == isICloudOn)
            #expect(ICloudSyncOperations.isEnabled(store: store) == (isActive && isICloudOn))
        }
    }

    @Test
    func explicitOffDuringLapsePreventsRenewalFromEnablingSync() throws {
        try withStore { _, store in
            store.set(true, for: \.stallyICloudEnabled)
            ICloudSyncOperations.updateSubscriptionAccess(.active, store: store)
            ICloudSyncOperations.updateSubscriptionAccess(.inactive, store: store)
            store.set(false, for: \.stallyICloudEnabled)
            ICloudSyncOperations.updateSubscriptionAccess(.active, store: store)
            #expect(!ICloudSyncOperations.isEnabled(store: store))
            #expect(!store.bool(for: \.stallyICloudEnabled))
        }
    }

    @Test
    func firstPurchaseDoesNotOptIntoSync() throws {
        try withStore { _, store in
            #expect(!ICloudSyncOperations.isEnabled(store: store))
            ICloudSyncOperations.updateSubscriptionAccess(.active, store: store)
            #expect(!ICloudSyncOperations.isEnabled(store: store))
            #expect(!store.bool(for: \.stallyICloudEnabled))
        }
    }
}

private extension ICloudSyncOperationsTests {
    func withStore(_ operation: (String, MHPreferenceStore) throws -> Void) throws {
        let suiteName = "ICloudSyncOperationsTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        try operation(suiteName, .init(userDefaults: defaults))
    }
}
