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

    @MainActor private static var liveRoutePipeline: StallyRoutePipeline?

    @MainActor
    static func registerLiveRoutePipeline(
        _ routePipeline: StallyRoutePipeline
    ) {
        liveRoutePipeline = routePipeline
    }

    @MainActor
    static func store(_ url: URL) async {
        deepLinkStore.ingest(url)
        await liveRoutePipeline?.synchronizePendingRoutesIfPossible()
    }
}
