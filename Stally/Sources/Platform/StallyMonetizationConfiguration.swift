import MHAppRuntime
import MHAppRuntimeDefaults
import MHAppRuntimeLicenses

@MainActor
enum StallyMonetizationConfiguration {
    static let subscriptionProductID = "com.muhiro12.Stally.subscriptions.monthly"

    static func makeBootstrap() -> MHAppRuntimeBootstrap {
        let configuration = MHAppConfiguration(subscriptionProductIDs: [subscriptionProductID])
        let defaults = MHAppRuntimeDefaultsBundle(configuration: configuration)
        let licenses = MHAppRuntimeLicensesBundle(configuration: configuration)
        return .init(
            runtime: .init(
                configuration: configuration,
                preferenceStore: defaults.preferenceStore,
                startStore: defaults.startStore,
                subscriptionSectionFactory: defaults.subscriptionSectionFactory,
                startAds: nil,
                nativeAdFactory: nil,
                licensesFactory: licenses.licensesFactory
            )
        )
    }
}
