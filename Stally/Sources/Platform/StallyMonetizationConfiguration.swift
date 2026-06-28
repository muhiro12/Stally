//
//  StallyMonetizationConfiguration.swift
//  Stally
//
//  Created by Codex on 2026/06/28.
//

enum StallyMonetizationConfiguration {
    static let subscriptionProductID = "com.muhiro12.Stally.subscriptions.monthly"
    static let nativeAdUnitIDDev = "ca-app-pub-3940256099942544/3986624511"

    static func nativeAdUnitID(
        for platformMode: StallyPlatformMode
    ) -> String? {
        switch platformMode {
        case .production:
            #if DEBUG
            nativeAdUnitIDDev
            #else
            nil
            #endif
        case .preview:
            nativeAdUnitIDDev
        }
    }
}
