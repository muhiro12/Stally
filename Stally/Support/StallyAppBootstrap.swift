//
//  StallyAppBootstrap.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/08.
//

import MHPlatform

@MainActor
struct StallyAppBootstrap {
    let appRuntime: MHAppRuntime
    let deepLinkInbox: MHObservableDeepLinkInbox

    static func make() -> Self {
        .init(
            appRuntime: MHAppRuntime(
                configuration: StallyAppConfiguration.runtimeConfiguration
            ),
            deepLinkInbox: .init()
        )
    }
}
