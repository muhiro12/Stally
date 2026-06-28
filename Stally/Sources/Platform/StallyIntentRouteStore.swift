//
//  StallyIntentRouteStore.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import Foundation
import MHPlatform

enum StallyIntentRouteStore {
    static let storageDescriptor = MHRawStorageDescriptor(
        storageKey: "com.muhiro12.Stally.pendingDeepLinkURL",
        defaultSelection: .standard
    )

    private static let deepLinkStore = MHDeepLinkStore(
        key: storageDescriptor
    )

    static var source: MHDeepLinkStore? {
        deepLinkStore
    }

    static func store(_ url: URL) {
        deepLinkStore.ingest(url)
    }
}
