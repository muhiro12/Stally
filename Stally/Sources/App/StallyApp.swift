//
//  StallyApp.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

import MHUI
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
            rootContent
                .mhTheme(.standard)
                .mhGlassPolicy(.automatic)
        }
        .modelContainer(sharedModelContainer)
    }

    @ViewBuilder private var rootContent: some View {
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
}
