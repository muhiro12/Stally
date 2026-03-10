import Foundation
#if canImport(LicenseList)
import LicenseList
#endif
import MHAppRuntimeCore
import MHPreferences
import SwiftUI

enum StallyPlatformRuntime {
    @MainActor
    static func make(
        configuration: MHAppConfiguration
    ) -> MHAppRuntime {
        // swiftlint:disable multiple_closures_with_trailing_closure opening_brace
        MHAppRuntime(
            configuration: configuration,
            preferenceStore: .init(
                userDefaults: makeUserDefaults(
                    suiteName: configuration.preferencesSuiteName
                )
            ),
            startStore: { purchasedProductIDsDidSet in
                purchasedProductIDsDidSet([])
            },
            subscriptionSectionViewBuilder: {
                AnyView(EmptyView())
            },
            startAds: nil,
            nativeAdViewBuilder: nil
        )            {
            guard configuration.showsLicenses else {
                return AnyView(EmptyView())
            }

            #if canImport(LicenseList)
            return AnyView(
                LicenseList.LicenseListView()
                    .licenseViewStyle(.withRepositoryAnchorLink)
            )
            #else
            return AnyView(
                Text("License list is unavailable on this platform.")
                    .foregroundStyle(.secondary)
            )
            #endif
        }
        // swiftlint:enable multiple_closures_with_trailing_closure opening_brace
    }
}

private extension StallyPlatformRuntime {
    static func makeUserDefaults(
        suiteName: String?
    ) -> UserDefaults {
        guard let normalizedSuiteName = normalizeText(suiteName),
              let userDefaults = UserDefaults(
                suiteName: normalizedSuiteName
              ) else {
            return .standard
        }

        return userDefaults
    }

    static func normalizeText(
        _ text: String?
    ) -> String? {
        guard let text else {
            return nil
        }

        let normalized = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard normalized.isEmpty == false else {
            return nil
        }

        return normalized
    }
}
