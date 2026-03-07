//
//  StallyAppBootstrap.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/08.
//

import MHPlatform
import StallyLibrary
import SwiftData

@MainActor
struct StallyAppBootstrap {
    let modelContainer: ModelContainer
    let appRuntime: MHAppRuntime
    let deepLinkInbox: MHObservableDeepLinkInbox

    static func make() -> Self {
        let modelContainer: ModelContainer

        do {
            modelContainer = try ModelContainerFactory.shared()
        } catch {
            preconditionFailure("Failed to initialize the Stally model container: \(error)")
        }

        return .init(
            modelContainer: modelContainer,
            appRuntime: MHAppRuntime(
                configuration: StallyAppConfiguration.runtimeConfiguration
            ),
            deepLinkInbox: .init()
        )
    }
}
