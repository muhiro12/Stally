//
//  StallyAppConfiguration.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/08.
//

import Foundation
import MHPlatform

enum StallyAppConfiguration {
    static let displayName = "Stally"
    static let conceptLine = "An app for marking your own actions and quietly building up counts."
    static let baselineNote = "This is the app baseline built on MHPlatform, ready for future features."

    static var runtimeConfiguration: MHAppConfiguration {
        .init(
            subscriptionProductIDs: [],
            subscriptionGroupID: nil,
            nativeAdUnitID: nil,
            preferencesSuiteName: Bundle.main.bundleIdentifier,
            showsLicenses: true
        )
    }
}
