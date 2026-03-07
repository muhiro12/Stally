//
//  StallyApp.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/07.
//

import SwiftUI
import SwiftData

@main
struct StallyApp: App {
    private static let hasSeededInitialSampleDataKey = "hasSeededInitialSampleData"

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TrackedItem.self,
            CountEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            seedInitialSampleDataIfNeeded(in: container)
            return container
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

    private static func seedInitialSampleDataIfNeeded(in container: ModelContainer) {
        let defaults = UserDefaults.standard

        guard defaults.bool(forKey: hasSeededInitialSampleDataKey) == false else {
            return
        }

        let context = container.mainContext
        let fetchDescriptor = FetchDescriptor<TrackedItem>()

        do {
            let existingItems = try context.fetch(fetchDescriptor)

            guard existingItems.isEmpty else {
                defaults.set(true, forKey: hasSeededInitialSampleDataKey)
                return
            }

            let now = Date()
            let samples: [(name: String, offsets: [TimeInterval])] = [
                ("丸ノ内線", [-60 * 60, -26 * 60 * 60, -3 * 24 * 60 * 60, -5 * 24 * 60 * 60, -8 * 24 * 60 * 60]),
                ("グレーの靴下", [-6 * 60 * 60, -32 * 60 * 60, -4 * 24 * 60 * 60]),
                ("いつものカフェ", [-30 * 60 * 60, -6 * 24 * 60 * 60, -9 * 24 * 60 * 60]),
                ("ネイビーのコート", [-4 * 24 * 60 * 60, -11 * 24 * 60 * 60]),
            ]

            for sample in samples {
                let earliestOffset = sample.offsets.min() ?? 0
                let item = TrackedItem(
                    name: sample.name,
                    createdAt: now.addingTimeInterval(earliestOffset - 2 * 60 * 60)
                )
                context.insert(item)

                for offset in sample.offsets.sorted() {
                    item.recordCount(at: now.addingTimeInterval(offset))
                }
            }

            try context.save()
            defaults.set(true, forKey: hasSeededInitialSampleDataKey)
        } catch {
            assertionFailure("Failed to seed initial sample data: \(error)")
        }
    }
}
