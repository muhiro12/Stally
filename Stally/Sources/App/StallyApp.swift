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
    var sharedModelContainer: ModelContainer = {
        do {
            return try StallyModelContainerFactory.persistent()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
