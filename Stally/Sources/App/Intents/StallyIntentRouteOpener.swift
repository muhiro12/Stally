//
//  StallyIntentRouteOpener.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import Foundation

enum StallyIntentRouteOpener {
    static func routeIntent(for link: StallyLink) -> OpenStallyRouteIntent {
        .init(url: StallyLinkOperations.url(for: link))
    }

    static func store(_ link: StallyLink) {
        StallyIntentRouteStore.store(
            StallyLinkOperations.url(for: link)
        )
    }
}
