//
//  StallyApp.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import SwiftData
import SwiftUI

@main
struct StallyApp: App {
    #if DEBUG
    private static let previewLaunchConfiguration = StallyPreviewLaunchConfiguration.current
    #endif

    var sharedModelContainer: ModelContainer = {
        #if DEBUG
        if let modelContainer = Self.previewLaunchConfiguration.modelContainer {
            return modelContainer
        }
        #endif

        do {
            return try StallyModelContainerFactory.persistent()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if let route = Self.previewLaunchConfiguration.route {
                ContentView(initialPreviewRoute: route)
            } else {
                ContentView()
            }
            #else
            ContentView()
            #endif
        }
        .modelContainer(sharedModelContainer)
    }
}
